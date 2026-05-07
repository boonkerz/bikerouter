package main

import (
	"bytes"
	"encoding/binary"
	"encoding/xml"
	"errors"
	"fmt"
	"math"
	"strings"
	"time"

	"github.com/tormoder/fit"
)

// gpxDoc is a minimal slice of the GPX schema — just what we need to
// drop the points into a FIT Course.
type gpxDoc struct {
	XMLName xml.Name `xml:"gpx"`
	Tracks  []struct {
		Name     string `xml:"name"`
		Segments []struct {
			Points []struct {
				Lat float64 `xml:"lat,attr"`
				Lon float64 `xml:"lon,attr"`
				Ele float64 `xml:"ele"`
			} `xml:"trkpt"`
		} `xml:"trkseg"`
	} `xml:"trk"`
}

// gpxToFitCourse converts a GPX track into a Garmin FIT Course file
// suitable for /GARMIN/NEWFILES/. The course gets fixed-pace timestamps
// (cyclingSpeedMS) so the device can render an ETA.
const cyclingSpeedMS = 5.0 // 18 km/h, matches BRouter's default

func gpxToFitCourse(gpxData []byte, courseName string) ([]byte, error) {
	var doc gpxDoc
	if err := xml.Unmarshal(gpxData, &doc); err != nil {
		return nil, fmt.Errorf("gpx parse: %w", err)
	}

	type pt struct {
		lat, lon, ele float64
	}
	var pts []pt
	for _, trk := range doc.Tracks {
		for _, seg := range trk.Segments {
			for _, p := range seg.Points {
				pts = append(pts, pt{p.Lat, p.Lon, p.Ele})
			}
		}
	}
	if len(pts) < 2 {
		return nil, errors.New("gpx has fewer than 2 trkpts")
	}
	if courseName == "" {
		courseName = "Wegwiesel"
	}
	if len(courseName) > 15 {
		// Edge displays only ~15 chars and the FIT field is fixed-size.
		courseName = courseName[:15]
	}

	header := fit.NewHeader(fit.V20, false)
	file, err := fit.NewFile(fit.FileTypeCourse, header)
	if err != nil {
		return nil, err
	}
	now := time.Now().UTC()
	file.FileId.Type = fit.FileTypeCourse
	file.FileId.Manufacturer = fit.ManufacturerGarmin
	file.FileId.Product = 0
	file.FileId.TimeCreated = now
	file.FileId.SerialNumber = uint32(now.Unix())

	course, _ := file.Course()

	courseMsg := fit.NewCourseMsg()
	courseMsg.Name = courseName
	courseMsg.Sport = fit.SportCycling
	course.Course = courseMsg

	// Compute cumulative distance.
	cum := make([]float64, len(pts))
	for i := 1; i < len(pts); i++ {
		cum[i] = cum[i-1] + haversineMeters(pts[i-1].lat, pts[i-1].lon, pts[i].lat, pts[i].lon)
	}
	totalDist := cum[len(cum)-1]
	totalSec := totalDist / cyclingSpeedMS

	records := make([]*fit.RecordMsg, len(pts))
	for i, p := range pts {
		ts := now.Add(time.Duration(cum[i]/cyclingSpeedMS*1e9) * time.Nanosecond)
		r := fit.NewRecordMsg()
		r.Timestamp = ts
		r.PositionLat = fit.NewLatitudeDegrees(p.lat)
		r.PositionLong = fit.NewLongitudeDegrees(p.lon)
		if !math.IsNaN(p.ele) && p.ele > -500 && p.ele < 9000 {
			r.Altitude = uint16((p.ele + 500) * 5)
		}
		r.Distance = uint32(cum[i] * 100)
		r.Speed = uint16(cyclingSpeedMS * 1000)
		records[i] = r
	}
	course.Records = records

	lap := fit.NewLapMsg()
	lap.Timestamp = now.Add(time.Duration(totalSec*1e9) * time.Nanosecond)
	lap.StartTime = now
	lap.StartPositionLat = fit.NewLatitudeDegrees(pts[0].lat)
	lap.StartPositionLong = fit.NewLongitudeDegrees(pts[0].lon)
	lap.EndPositionLat = fit.NewLatitudeDegrees(pts[len(pts)-1].lat)
	lap.EndPositionLong = fit.NewLongitudeDegrees(pts[len(pts)-1].lon)
	lap.TotalElapsedTime = uint32(totalSec * 1000)
	lap.TotalTimerTime = uint32(totalSec * 1000)
	lap.TotalDistance = uint32(totalDist * 100)
	lap.Sport = fit.SportCycling
	course.Laps = []*fit.LapMsg{lap}

	var buf bytes.Buffer
	if err := fit.Encode(&buf, file, binary.LittleEndian); err != nil {
		return nil, fmt.Errorf("fit encode: %w", err)
	}
	return buf.Bytes(), nil
}

func haversineMeters(lat1, lon1, lat2, lon2 float64) float64 {
	const r = 6371000.0
	dLat := (lat2 - lat1) * math.Pi / 180
	dLon := (lon2 - lon1) * math.Pi / 180
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*math.Pi/180)*math.Cos(lat2*math.Pi/180)*
			math.Sin(dLon/2)*math.Sin(dLon/2)
	return 2 * r * math.Asin(math.Sqrt(a))
}

// sanitizeName strips characters that confuse Edge's course list view.
func sanitizeName(s string) string {
	s = strings.ReplaceAll(s, "→", "-")
	s = strings.ReplaceAll(s, "/", "-")
	return s
}
