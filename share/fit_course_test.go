package main

import (
	"bytes"
	"testing"

	"github.com/tormoder/fit"
)

const sampleGpx = `<?xml version="1.0"?>
<gpx version="1.1" creator="test"><trk><name>Test</name><trkseg>
<trkpt lat="48.137" lon="11.575"><ele>520.0</ele></trkpt>
<trkpt lat="48.140" lon="11.580"><ele>525.0</ele></trkpt>
<trkpt lat="48.145" lon="11.585"><ele>530.0</ele></trkpt>
</trkseg></trk></gpx>`

func TestGpxToFitRoundTrip(t *testing.T) {
	out, err := gpxToFitCourse([]byte(sampleGpx), "TestRoute")
	if err != nil {
		t.Fatalf("encode: %v", err)
	}
	if len(out) < 50 {
		t.Fatalf("FIT output suspiciously short: %d bytes", len(out))
	}
	decoded, err := fit.Decode(bytes.NewReader(out))
	if err != nil {
		t.Fatalf("decode: %v", err)
	}
	if decoded.Type() != fit.FileTypeCourse {
		t.Fatalf("file type = %s, want Course", decoded.Type())
	}
	c, err := decoded.Course()
	if err != nil {
		t.Fatalf("course: %v", err)
	}
	if c.Course == nil || c.Course.Name != "TestRoute" {
		t.Errorf("course name not preserved (got %v)", c.Course)
	}
	if got := len(c.Records); got != 3 {
		t.Errorf("records = %d, want 3", got)
	}
	if len(c.Laps) != 1 {
		t.Errorf("laps = %d, want 1", len(c.Laps))
	}
}
