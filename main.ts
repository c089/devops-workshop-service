let shutdown = false;

async function serveHttp(conn: Deno.Conn) {
  const httpConn = Deno.serveHttp(conn);
  for await (const requestEvent of httpConn) {
    console.log(`Received a friendly request, responding with a greeting.`);
    requestEvent.respondWith(
      new Response("Hello lovelies! " + Deno.env.get("HOSTNAME") + " : " + Deno.inspect(requestEvent.request), { status: 200 }),
    );
    if (shutdown) break;
  }
}

if (import.meta.main) {
  Deno.addSignalListener("SIGINT", () => {
    console.log("Received SIGINT, finishing up requests");
    shutdown = true;
  });
  
  const server = Deno.listen({ port: 8080 });
  console.log(`Hello service waiting for friendly greeting requests. ${Deno.env.get("HOSTNAME")}`);

  for await (const conn of server) {
    serveHttp(conn);
    if (shutdown) break;
  }
}
