// Pure helpers for the live maps, kept apart so they can be tested without Google's script.

export interface LatLng {
  lat: number;
  lng: number;
}

const METRES_PER_DEGREE = 111_320;

/** Maps NFR-004: arrow keys move the picker pin by about 10 m. */
export function nudge(point: LatLng, key: string, metres = 10): LatLng | null {
  const dLat = metres / METRES_PER_DEGREE;
  const dLng = metres / (METRES_PER_DEGREE * Math.max(Math.cos((point.lat * Math.PI) / 180), 0.01));
  switch (key) {
    case 'ArrowUp':
      return { lat: Math.min(point.lat + dLat, 90), lng: point.lng };
    case 'ArrowDown':
      return { lat: Math.max(point.lat - dLat, -90), lng: point.lng };
    case 'ArrowLeft':
      return { lat: point.lat, lng: wrapLng(point.lng - dLng) };
    case 'ArrowRight':
      return { lat: point.lat, lng: wrapLng(point.lng + dLng) };
    default:
      return null;
  }
}

function wrapLng(lng: number): number {
  return ((((lng + 180) % 360) + 360) % 360) - 180;
}

export interface PixelPoint {
  x: number;
  y: number;
}

export interface Cluster {
  /** Indexes into the input points. */
  members: number[];
  x: number;
  y: number;
}

/**
 * Greedy clustering in screen pixels (FR-020): each point joins the first cluster whose centre is
 * within `radius`, else starts one. Communities have tens of activities, so O(n²) is fine.
 */
export function clusterPoints(points: PixelPoint[], radius = 44): Cluster[] {
  const clusters: (Cluster & { sx: number; sy: number })[] = [];
  points.forEach((p, i) => {
    const near = clusters.find((c) => Math.hypot(c.x - p.x, c.y - p.y) <= radius);
    if (near) {
      near.members.push(i);
      near.sx += p.x;
      near.sy += p.y;
      near.x = near.sx / near.members.length;
      near.y = near.sy / near.members.length;
    } else {
      clusters.push({ members: [i], x: p.x, y: p.y, sx: p.x, sy: p.y });
    }
  });
  return clusters.map(({ members, x, y }) => ({ members, x, y }));
}
