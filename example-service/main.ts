async function serveHttp(conn: Deno.Conn) {
  const httpConn = Deno.serveHttp(conn);
  for await (const requestEvent of httpConn) {
    console.log(`Received a friendly request, responding with a greeting.`);
    requestEvent.respondWith(
      new Response("Hello!", { status: 200 }),
    );
  }
}

if (import.meta.main) {
  const server = Deno.listen({ port: 8080 });
  console.log(`Hello service waiting for friendly greeting requests.`);

  for await (const conn of server) {
    serveHttp(conn);
  }
}
