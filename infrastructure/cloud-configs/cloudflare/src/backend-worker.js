/**
 * Backend Service Worker
 * Routes requests to the Go Backend container
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // Health check endpoint
    if (url.pathname === '/health') {
      return new Response(JSON.stringify({
        status: 'ok',
        service: 'backend',
        timestamp: new Date().toISOString()
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Route to container
    try {
      // Forward request to container
      const containerResponse = await env.BACKEND_CONTAINER.fetch(request);
      return containerResponse;
    } catch (error) {
      return new Response(JSON.stringify({
        error: 'Container unavailable',
        message: error.message
      }), {
        status: 503,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  }
};

