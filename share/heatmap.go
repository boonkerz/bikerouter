package main

import (
	"bytes"
	"encoding/xml"
	"image"
	"image/color"
	"image/png"
	"math"
	"net/http"
	"strconv"
	"strings"
)

const heatmapZoom = 12

// aggregateRouteIntoHeatmap parses a GPX document and bumps the tile counter
// for every unique zoom-12 tile that the route touches. Called once when a
// share is published.
func aggregateRouteIntoHeatmap(gpx []byte) error {
	type trkpt struct {
		Lat float64 `xml:"lat,attr"`
		Lon float64 `xml:"lon,attr"`
	}
	type trkseg struct {
		Pts []trkpt `xml:"trkpt"`
	}
	type trk struct {
		Segs []trkseg `xml:"trkseg"`
	}
	type doc struct {
		Tracks []trk `xml:"trk"`
	}
	var d doc
	if err := xml.NewDecoder(bytes.NewReader(gpx)).Decode(&d); err != nil {
		return err
	}
	tiles := map[[2]int]struct{}{}
	for _, t := range d.Tracks {
		for _, s := range t.Segs {
			for _, p := range s.Pts {
				x, y := latLonToTile(p.Lat, p.Lon, heatmapZoom)
				tiles[[2]int{x, y}] = struct{}{}
			}
		}
	}
	if len(tiles) == 0 {
		return nil
	}
	tx, err := db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback() //nolint:errcheck
	stmt, err := tx.Prepare(
		`INSERT INTO tile_counters (z, x, y, count) VALUES (?, ?, ?, 1)
		 ON CONFLICT(z, x, y) DO UPDATE SET count = count + 1`,
	)
	if err != nil {
		return err
	}
	defer stmt.Close()
	for k := range tiles {
		if _, err := stmt.Exec(heatmapZoom, k[0], k[1]); err != nil {
			return err
		}
	}
	return tx.Commit()
}

// serveHeatmapTile renders a transparent 256×256 PNG with red squares for
// each child tile of (z,x,y) at the native heatmap zoom (12). For zoom
// levels >= 12, downscaling falls back to a single colored square keyed by
// the parent's count. Always returns a 200 (empty PNG) so the client's
// TileLayer doesn't show a missing-tile cross.
func serveHeatmapTile(w http.ResponseWriter, r *http.Request) {
	z, err1 := strconv.Atoi(r.PathValue("z"))
	x, err2 := strconv.Atoi(r.PathValue("x"))
	// y can be "1407" or "1407.png" — accept both for browser caching.
	yRaw := r.PathValue("y")
	yRaw = strings.TrimSuffix(yRaw, ".png")
	y, err3 := strconv.Atoi(yRaw)
	if err1 != nil || err2 != nil || err3 != nil {
		http.Error(w, "bad path", http.StatusBadRequest)
		return
	}
	if z < 3 || z > 16 {
		writeEmptyTile(w)
		return
	}

	img := image.NewNRGBA(image.Rect(0, 0, 256, 256))

	if z <= heatmapZoom {
		// Aggregate every native-zoom tile that falls inside this parent.
		scale := 1 << (heatmapZoom - z)
		xStart := x * scale
		yStart := y * scale
		xEnd := xStart + scale
		yEnd := yStart + scale
		rows, err := db.Query(
			`SELECT x, y, count FROM tile_counters
			 WHERE z = ? AND x >= ? AND x < ? AND y >= ? AND y < ?`,
			heatmapZoom, xStart, xEnd, yStart, yEnd,
		)
		if err != nil {
			writeEmptyTile(w)
			return
		}
		defer rows.Close()

		px := 256 / scale
		if px < 1 {
			px = 1
		}
		for rows.Next() {
			var tx, ty, count int
			if err := rows.Scan(&tx, &ty, &count); err != nil {
				continue
			}
			localX := (tx - xStart) * px
			localY := (ty - yStart) * px
			paintTileCell(img, localX, localY, px, count)
		}
	} else {
		// Zoom level deeper than the native: every requested tile is a
		// sub-region of one parent tile at zoom 12. Look that parent up
		// and paint the full 256×256 with its alpha.
		scale := 1 << (z - heatmapZoom)
		parentX := x / scale
		parentY := y / scale
		var count int
		row := db.QueryRow(
			`SELECT count FROM tile_counters WHERE z = ? AND x = ? AND y = ?`,
			heatmapZoom, parentX, parentY,
		)
		_ = row.Scan(&count)
		if count > 0 {
			paintTileCell(img, 0, 0, 256, count)
		}
	}

	w.Header().Set("Content-Type", "image/png")
	w.Header().Set("Cache-Control", "public, max-age=300")
	_ = png.Encode(w, img)
}

func paintTileCell(img *image.NRGBA, x, y, size, count int) {
	if count <= 0 {
		return
	}
	// Compress the very wide possible counter range to 0–255 alpha so a
	// route that's been published once is still visible and a popular
	// corridor doesn't drown everything else.
	alpha := int(math.Min(255, math.Log2(float64(count)+1)*40))
	c := color.NRGBA{R: 220, G: 30, B: 30, A: uint8(alpha)}
	for j := 0; j < size; j++ {
		for i := 0; i < size; i++ {
			img.SetNRGBA(x+i, y+j, c)
		}
	}
}

func writeEmptyTile(w http.ResponseWriter) {
	w.Header().Set("Content-Type", "image/png")
	w.Header().Set("Cache-Control", "public, max-age=300")
	img := image.NewNRGBA(image.Rect(0, 0, 256, 256))
	_ = png.Encode(w, img)
}

func latLonToTile(lat, lon float64, zoom int) (int, int) {
	n := math.Exp2(float64(zoom))
	x := int(math.Floor((lon + 180) / 360 * n))
	latRad := lat * math.Pi / 180
	y := int(math.Floor((1 - math.Log(math.Tan(latRad)+1/math.Cos(latRad))/math.Pi) / 2 * n))
	return x, y
}

