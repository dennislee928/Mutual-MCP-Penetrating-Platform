/**
 * Custom image loader for static export
 * This ensures images work correctly in static deployment
 */
export default function imageLoader({ src, width, quality }) {
  // For static export, return the src as-is
  // Images should be optimized during build time
  return src;
}