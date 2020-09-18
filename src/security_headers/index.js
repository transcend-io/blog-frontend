/**
 * Adds security headers to a response.
 */
exports.handler = (event, context, callback) => {
  // Get contents of response
  const response = event.Records[0].cf.response;
  const headers = response.headers;

  // Set new headers
  headers['strict-transport-security'] = [{key: 'Strict-Transport-Security', value: 'max-age= 63072000; includeSubdomains; preload'}];
  headers['content-security-policy'] = [{key: 'Content-Security-Policy', value: "default-src 'self' cdnjs.cloudflare.com style-src 'self' 'unsafe-inline';"}];
  headers['x-frame-options'] = [{key: 'X-Frame-Options', value: 'DENY'}];
  headers['x-xss-protection'] = [{key: 'X-XSS-Protection', value: '1; mode=block'}];
  headers['referrer-policy'] = [{key: 'Referrer-Policy', value: 'same-origin'}];

  // Return modified response
  callback(null, response);
};