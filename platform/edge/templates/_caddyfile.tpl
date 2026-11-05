{{- define "edge.proxy" -}}
reverse_proxy {{ . }} {
    header_up -X-Ypm-Origin
    header_up X-Forwarded-Proto https
    # The viewer's IP (Yourplaymat's geo lookup and the translation
    # services' per-IP limit read it).
    header_up X-Real-IP {client_ip}
}
{{- end }}

{{- define "edge.caddyfile" -}}
# Rendered from platform/edge (ypm-platform). Only CloudFront reaches this
# listener (the node's security group). Each distribution adds X-Ypm-Origin,
# which selects the upstream; anything else gets a 404.
{
    admin off
    persist_config off
    auto_https off
    grace_period 20s

    servers {
        # CloudFront's origin-facing ranges. Trusting them makes {client_ip}
        # the viewer and has reverse_proxy append to X-Forwarded-For instead
        # of replacing it.
        trusted_proxies static {{ join " " .Values.trustedProxies }}
        # Right to left: the viewer address CloudFront appended, not one the
        # viewer sent itself.
        trusted_proxies_strict
        client_ip_headers X-Forwarded-For
    }

    log {
        output stdout
        format json
    }
}

:8080 {
    log {
        output stdout
        format json
    }
{{ range $name, $route := .Values.routes }}
{{- $upstream := $route }}
{{- $paths := dict }}
{{- if kindIs "map" $route }}
{{- $upstream = required (printf "routes.%s.upstream is required" $name) $route.upstream }}
{{- $paths = $route.paths | default dict }}
{{- end }}
    @{{ $name }} header X-Ypm-Origin {{ $name }}
    handle @{{ $name }} {
{{- if $paths }}
{{- range $path, $pathUpstream := $paths }}
        handle {{ $path }} {
            {{- include "edge.proxy" $pathUpstream | nindent 12 }}
        }
{{- end }}
        handle {
            {{- include "edge.proxy" $upstream | nindent 12 }}
        }
{{- else }}
        {{- include "edge.proxy" $upstream | nindent 8 }}
{{- end }}
    }
{{ end }}
    handle {
        respond 404
    }
}

# Kubelet probes only; the Service doesn't expose this port.
:8081 {
    respond /healthz 200
}
{{- end }}
