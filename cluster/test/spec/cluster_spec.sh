Include spec/support.sh

Describe 'k3d development cluster'

  Describe "Traefik"
    It "redirects http to https"
      Pending "configure traefik entryPoint"
      When call curl $CURL_ARGS -I "http://any-service.k3d.localhost/"
      The status should be success
      The result of "redirect_url()" should equal "https://any-service.k3d.localhost/"
    End

    It "uses a valid certificate"
      Pending "create and configure a default certificate for *.k3d.localhost"
      When call curl ${CURL_ARGS} --no-fail --no-insecure https://any-service.k3d.localhost/
      The status should be success
      The result of "ssl_verify_result()" should equal ${CURL_SSL_VERIFY_SUCCESS}
    End

    It "exposes the Traefik dashboard"
      Pending "replace traefik-dashboard ingressroute"
      When call curl $CURL_ARGS https://traefik-dashboard.k3d.localhost/dashboard/
      The status should be success
      The result of "http_code()" should equal "200"
    End
  End

  Describe "Argo CD"
    It "exposes the web interface"
      Pending "install argo-cd helm chart"
      When call curl $CURL_ARGS https://argocd.k3d.localhost/
      The status should be success
      The result of "http_code()" should equal "200"
    End
  End

  Describe "Prometheus"
    It "exposes the web interface"
      Pending "add ingressroute"
      When call curl $CURL_ARGS https://prometheus.k3d.localhost/graph
      The status should be success
      The result of "http_code()" should equal "200"
    End
  End

  Describe "Grafana"
    Pending "Install kube-prometheus-stack and loki-stack"
    grafana_datasources() { env echo "$1" | jq -r '.data.result[].metric.plugin_id' ; }

    It "exposes the Grafana interface"
      When call curl $CURL_ARGS https://grafana.k3d.localhost/
      The status should be success
      The result of "http_code()" should equal "302"
      The result of "redirect_url()" should equal "https://grafana.k3d.localhost/login"
    End

    It "has Loki configured as datasource"
      When call curl $CURL_ARGS_API https://prometheus.k3d.localhost/api/v1/query\?query='grafana_stat_totals_datasource'
      The status should be success
      The result of "grafana_datasources()" should include "loki"
    End

    It "can query Loki"
      When call grafana_loki_query_instant 'count_over_time({app=\"loki\"}[15m])'
      The output should satisfy formula "value > 0"
    End

    It "has Prometheus configured datasource"
      When call curl $CURL_ARGS_API https://prometheus.k3d.localhost/api/v1/query\?query='grafana_stat_totals_datasource'
      The status should be success
      The result of "grafana_datasources()" should include "prometheus"
    End

    It "can query Prometheus"
      extract_version_label() {
        env echo -n "$1" | jq -j \
          '.results.A.frames[0].schema.fields | map(select (.name == "Value")) | first | .labels.version'
      }
      When call grafana_prometheus_query_instant 'grafana_build_info'
      The result of "extract_version_label()" should equal "9.2.4"
    End
  End

End
