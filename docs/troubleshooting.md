# Troubleshooting

Some things to try.

## Is the server started?

If you don't see "ready to rock! 🪨" in your logs, it's not started. Scroll back and look for errors!

## Can you connect?

If the server's running on `idm.example.com:8443` then a simple connectivity test is done using [curl](https://curl.se).

Run the following command:

```shell
curl https://idm.example.com:8443/status
```

This is similar to what you _should_ see:

```shell
*   Trying 10.0.0.14:8443...
* Connected to idm.example.com (10.0.0.14) port 8443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/certs/ca-certificates.crt
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN, server accepted to use h2
* Server certificate:
*  subject: CN=idm.example.com
*  start date: Jan  1 00:00:00 2024 GMT
*  expire date: Dec 31 23:59:59 2025 GMT
*  subjectAltName: host "idm.example.com" matched cert's "idm.example.com"
*  issuer: CN=idm.example.com
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x5600c1c3e2e0)
> GET /status HTTP/2
> Host: idm.example.com:8443
> user-agent: curl/7.74.0
> accept: */*
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* Connection state changed (MAX_CONCURRENT_STREAMS == 100)!
< HTTP/2 200
< content-type: application/json
< content-length: 4
< date: Thu, 01 Jan 2024 12:00:00 GMT
<
* Connection #0 to host idm.example.com left intact
true
```

This means:

1. you've successfully connected to a host (10.0.0.14),
2. TLS worked
3. Received the status response "true"

If you see something like this:

```shell
➜ curl -v https://idm.example.com:8443
*   Trying 10.0.0.1:8443...
* connect to 10.0.0.1 port 8443 failed: Connection refused
* Failed to connect to idm.example.com port 8443 after 5 ms: Connection refused
* Closing connection 0
curl: (7) Failed to connect to idm.example.com port 8443 after 5 ms: Connection refused
```

Then either your DNS is wrong (it's pointing at 10.0.0.1) or you can't connect to the server for some reason.

If you get errors about certificates, try adding `-k` to skip certificate verification checking and just test
connectivity:

```shell
curl -vk https://idm.example.com:8443/status
```

## Server things to check

- Has the config file got `bindaddress = "127.0.0.1:8443"` ? Change it to `bindaddress = "[::]:8443"`, so it listens on
  all interfaces.
- Is there a firewall on the server?
- If you're running in docker, did you expose the port (`-p 8443:8443`) or configure the network to host/macvlan/ipvlan?

## Client errors

When you receive a client error it will list an "Operation ID" sometimes also called the OpId or KOpId. This UUID
matches to the UUID's in the logs allowing you to precisely locate the server logs related to the failing operation.

Try running commands with `RUST_LOG=debug` to get more information:

```shell
RUST_LOG=debug kanidm login --name anonymous
```

## Reverse Proxies not sending HTTP/1.1 requests

NGINX (and probably other proxies) send HTTP/1.0 requests to the upstream server by default. This'll lead to errors like
this in your proxy logs:

```text
*17 upstream prematurely closed connection while reading response header from upstream, client: 172.19.0.1, server: example.com, request: "GET / HTTP/1.1", upstream: "https://172.19.0.3:8443/", host: "example.com:8443"
```

The fix for NGINX is to set the
[proxy_http_version](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_http_version) to `1.1`. This can go
in the same block as the `proxy_pass` option.

```text
proxy_http_version 1.1
```

## OpenTelemetry errors

If you see something like this:

> `OpenTelemetry trace error occurred. Exporter otlp encountered the following error(s): the grpc server returns error (The system is not in a state required for the operation's execution): , detailed error message: TRACE_TOO_LARGE: max size of trace (5000000) exceeded while adding 86725 bytes to trace a657b63f6ca0415eb70b6734f20f82cf for tenant single-tenant`

Then you'll need to tweak the maximum trace size in your OTLP receiver. In Grafana Tempo you can add the following keys
to your `tempo.yaml`, in this example we're setting it to 20MiB:

```yaml
overrides:
  defaults:
    global:
      max_bytes_per_trace: 20971520 # 20MiB
```
