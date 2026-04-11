import * as d3 from 'd3';

export interface ElevationPoint {
  distance: number; // km
  elevation: number; // m
  lng: number;
  lat: number;
}

export type HoverCallback = (point: ElevationPoint | null) => void;

let onHover: HoverCallback | null = null;

export function setHoverCallback(cb: HoverCallback): void {
  onHover = cb;
}

export function renderElevation(
  container: string,
  coordinates: [number, number, number][]
): void {
  const el = document.getElementById(container);
  if (!el) return;
  el.innerHTML = '';

  const points = buildElevationData(coordinates);
  if (points.length === 0) return;

  const rect = el.getBoundingClientRect();
  const margin = { top: 12, right: 16, bottom: 28, left: 48 };
  const width = rect.width - margin.left - margin.right;
  const height = rect.height - margin.top - margin.bottom;

  if (width <= 0 || height <= 0) return;

  const svg = d3.select(`#${container}`)
    .append('svg')
    .attr('viewBox', `0 0 ${rect.width} ${rect.height}`);

  const g = svg.append('g')
    .attr('transform', `translate(${margin.left},${margin.top})`);

  const xScale = d3.scaleLinear()
    .domain([0, points[points.length - 1].distance])
    .range([0, width]);

  const elevExtent = d3.extent(points, d => d.elevation) as [number, number];
  const elevPadding = (elevExtent[1] - elevExtent[0]) * 0.1 || 50;
  const yScale = d3.scaleLinear()
    .domain([elevExtent[0] - elevPadding, elevExtent[1] + elevPadding])
    .range([height, 0]);

  // Grid lines
  g.append('g')
    .attr('class', 'elevation-grid')
    .call(d3.axisLeft(yScale).tickSize(-width).tickFormat(() => ''))
    .call(g => g.select('.domain').remove());

  // Area
  const area = d3.area<ElevationPoint>()
    .x(d => xScale(d.distance))
    .y0(height)
    .y1(d => yScale(d.elevation))
    .curve(d3.curveMonotoneX);

  g.append('path')
    .datum(points)
    .attr('class', 'elevation-area')
    .attr('d', area);

  // Line
  const line = d3.line<ElevationPoint>()
    .x(d => xScale(d.distance))
    .y(d => yScale(d.elevation))
    .curve(d3.curveMonotoneX);

  g.append('path')
    .datum(points)
    .attr('class', 'elevation-line')
    .attr('d', line);

  // Axes
  g.append('g')
    .attr('class', 'elevation-axis')
    .attr('transform', `translate(0,${height})`)
    .call(d3.axisBottom(xScale).ticks(8).tickFormat(d => `${d} km`));

  g.append('g')
    .attr('class', 'elevation-axis')
    .call(d3.axisLeft(yScale).ticks(5).tickFormat(d => `${d} m`));

  // Crosshair + tooltip
  const crosshairLine = g.append('line')
    .attr('class', 'elevation-crosshair')
    .attr('y1', 0)
    .attr('y2', height)
    .style('display', 'none');

  const tooltipGroup = g.append('g').style('display', 'none');

  tooltipGroup.append('rect')
    .attr('class', 'elevation-tooltip')
    .attr('width', 120)
    .attr('height', 36)
    .attr('rx', 4);

  const tooltipText1 = tooltipGroup.append('text')
    .attr('class', 'elevation-tooltip-text')
    .attr('x', 8)
    .attr('y', 14);

  const tooltipText2 = tooltipGroup.append('text')
    .attr('class', 'elevation-tooltip-text')
    .attr('x', 8)
    .attr('y', 28);

  const dot = g.append('circle')
    .attr('r', 4)
    .attr('fill', '#4fc3f7')
    .attr('stroke', '#fff')
    .attr('stroke-width', 1.5)
    .style('display', 'none');

  // Bisector for mouse position
  const bisect = d3.bisector<ElevationPoint, number>(d => d.distance).left;

  // Interaction overlay
  g.append('rect')
    .attr('width', width)
    .attr('height', height)
    .attr('fill', 'transparent')
    .on('mousemove', (event: MouseEvent) => {
      const [mx] = d3.pointer(event);
      const dist = xScale.invert(mx);
      const idx = bisect(points, dist, 1);
      const p = points[Math.min(idx, points.length - 1)];

      crosshairLine
        .attr('x1', xScale(p.distance))
        .attr('x2', xScale(p.distance))
        .style('display', null);

      dot
        .attr('cx', xScale(p.distance))
        .attr('cy', yScale(p.elevation))
        .style('display', null);

      const tx = Math.min(xScale(p.distance) + 8, width - 128);
      tooltipGroup
        .attr('transform', `translate(${tx},${4})`)
        .style('display', null);

      tooltipText1.text(`${p.distance.toFixed(1)} km`);
      tooltipText2.text(`${Math.round(p.elevation)} m`);

      onHover?.(p);
    })
    .on('mouseleave', () => {
      crosshairLine.style('display', 'none');
      dot.style('display', 'none');
      tooltipGroup.style('display', 'none');
      onHover?.(null);
    });
}

function buildElevationData(coords: [number, number, number][]): ElevationPoint[] {
  const points: ElevationPoint[] = [];
  let dist = 0;

  for (let i = 0; i < coords.length; i++) {
    if (i > 0) {
      dist += haversineKm(coords[i - 1], coords[i]);
    }
    // Sample every ~50m to keep rendering fast
    if (i === 0 || i === coords.length - 1 || dist - (points[points.length - 1]?.distance ?? 0) > 0.05) {
      points.push({
        distance: dist,
        elevation: coords[i][2],
        lng: coords[i][0],
        lat: coords[i][1],
      });
    }
  }
  return points;
}

function haversineKm(a: [number, number, number], b: [number, number, number]): number {
  const R = 6371;
  const dLat = (b[1] - a[1]) * Math.PI / 180;
  const dLon = (b[0] - a[0]) * Math.PI / 180;
  const lat1 = a[1] * Math.PI / 180;
  const lat2 = b[1] * Math.PI / 180;
  const x = Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(x), Math.sqrt(1 - x));
}

export function clearElevation(container: string): void {
  const el = document.getElementById(container);
  if (el) el.innerHTML = '';
}
