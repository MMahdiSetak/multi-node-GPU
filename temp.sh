curl -k -v -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "kerio_username=user-1696%40isiranco.internet&kerio_password=2wsx3edc%40WSX%23EDC" \
    https://192.168.10.2:4081/internal/dologin.php

curl -k -v -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "kerio_username=user-1696&kerio_password=4rfv5tgb%24RFV%25TGB" \
    https://192.168.10.2:4081/internal/dologin.php

kubeadm token create --print-join-command

kubectl get pods -A --field-selector spec.nodeName=worker-g01
kubectl delete pod -A --field-selector=status.phase=Succeeded
kubectl delete pod -A --field-selector=status.phase=Failed

kubectl taint node master node-role.kubernetes.io/control-plane:NoSchedule-

# delete kubeflow
kustomize build example | kubectl delete --ignore-not-found --server-side --force-conflicts -f -
kubectl delete namespace auth cert-manager istio-system knative-serving kubeflow kubeflow-user-example-com oauth2-proxy knative-eventing --force --grace-period=0
kubectl get namespace auth cert-manager istio-system knative-serving kubeflow kubeflow-user-example-com oauth2-proxy knative-eventing -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/<namespace>/finalize" -f -
kubectl get all,ingress,pvc,secrets,serviceaccounts,roles,clusterroles,clusterrolebindings,mutatingwebhookconfigurations,validatingwebhookconfigurations,crds -A | grep -E 'kubeflow|istio|knative|cert-manager'
kubectl get clusterroles |
    grep -E 'kubeflow|istio|knative|cert-manager' |
    awk '{print $1}' |
    xargs -I {} kubectl delete clusterrole {}
kubectl get clusterrolebindings |
    grep -E 'kubeflow|istio|knative|cert-manager' |
    awk '{print $1}' |
    xargs -I {} kubectl delete clusterrolebinding {}
kubectl get crd |
    grep -E 'kubeflow.org|istio.io|knative.dev|serving.kubeflow.org|cert-manager' |
    awk '{print $1}' |
    xargs kubectl delete crd --force --grace-period=0
kubectl delete mutatingwebhookconfigurations \
    $(kubectl get mutatingwebhookconfigurations | grep -E 'istio|kubeflow|cert-manager' | awk '{print $1}')
kubectl delete validatingwebhookconfigurations \
    $(kubectl get validatingwebhookconfigurations | grep -E 'istio|kubeflow|cert-manager' | awk '{print $1}')
kubectl delete clusterrolebinding meta-controller-cluster-role-binding

echo "Waiting for SSH on 192.168.20.139..."
until ssh -o BatchMode=yes \
    -o ConnectTimeout=5 \
    -o StrictHostKeyChecking=no \
    "setak@192.168.20.139" exit; do
    echo "  ⏳ SSH not ready yet – retrying in 5s…"
    sleep 5
done

systemctl set-default multi-user.target
systemctl set-default graphical.target

kubectl get pods --all-namespaces -o=jsonpath='{range .items[?(@.spec.volumes.persistentVolumeClaim.claimName=="storage-prometheus-alertmanager")]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}'

kubectl get pvc storage-prometheus-alertmanager-0 -o=jsonpath='{.spec.volumeName}'

kubectl describe pv pvc-bbefbc90-80a4-4138-911f-4c4a103cd61a

# use the k8s namespace if your node’s containerd is namespaced
sudo ctr images pull quay.io/prometheus-operator/prometheus-operator:v0.82.1



dnf config-manager --set-disabled cuda-rhel9-x86_64
dnf config-manager --set-disabled docker-ce-stable


####### Proxy settings
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

cat <<EOF | tee /usr/local/etc/xray/config.json
{
  "log": {
    "loglevel": "warning"
  },
  "dns": {
    "hosts": {
      "dns.google": [
        "8.8.8.8",
        "8.8.4.4",
        "2001:4860:4860::8888",
        "2001:4860:4860::8844"
      ],
      "dns.alidns.com": [
        "223.5.5.5",
        "223.6.6.6",
        "2400:3200::1",
        "2400:3200:baba::1"
      ],
      "one.one.one.one": [
        "1.1.1.1",
        "1.0.0.1",
        "2606:4700:4700::1111",
        "2606:4700:4700::1001"
      ],
      "1dot1dot1dot1.cloudflare-dns.com": [
        "1.1.1.1",
        "1.0.0.1",
        "2606:4700:4700::1111",
        "2606:4700:4700::1001"
      ],
      "cloudflare-dns.com": [
        "104.16.249.249",
        "104.16.248.249",
        "2606:4700::6810:f8f9",
        "2606:4700::6810:f9f9"
      ],
      "dns.cloudflare.com": [
        "104.16.132.229",
        "104.16.133.229",
        "2606:4700::6810:84e5",
        "2606:4700::6810:85e5"
      ],
      "dot.pub": [
        "1.12.12.12",
        "120.53.53.53"
      ],
      "dns.quad9.net": [
        "9.9.9.9",
        "149.112.112.112",
        "2620:fe::fe",
        "2620:fe::9"
      ],
      "dns.yandex.net": [
        "77.88.8.8",
        "77.88.8.1",
        "2a02:6b8::feed:0ff",
        "2a02:6b8:0:1::feed:0ff"
      ],
      "dns.sb": [
        "185.222.222.222",
        "2a09::"
      ],
      "dns.umbrella.com": [
        "208.67.220.220",
        "208.67.222.222",
        "2620:119:35::35",
        "2620:119:53::53"
      ],
      "dns.sse.cisco.com": [
        "208.67.220.220",
        "208.67.222.222",
        "2620:119:35::35",
        "2620:119:53::53"
      ],
      "engage.cloudflareclient.com": [
        "162.159.192.1",
        "2606:4700:d0::a29f:c001"
      ]
    },
    "servers": [
      {
        "address": "https://cloudflare-dns.com/dns-query",
        "domains": [
          "domain:googleapis.cn",
          "domain:gstatic.com"
        ],
        "skipFallback": true
      },
      {
        "address": "https://dns.alidns.com/dns-query",
        "domains": [
          "domain:alidns.com",
          "domain:doh.pub",
          "domain:dot.pub",
          "domain:360.cn",
          "domain:onedns.net",
          "tr.boilersforpellets.com"
        ],
        "skipFallback": true
      },
      {
        "address": "https://dns.alidns.com/dns-query",
        "domains": [
          "geosite:private",
          "geosite:cn"
        ],
        "skipFallback": true
      },
      "https://cloudflare-dns.com/dns-query"
    ]
  },
  "inbounds": [
    {
      "tag": "socks",
      "port": 10808,
      "listen": "127.0.0.1",
      "protocol": "mixed",
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ],
        "routeOnly": false
      },
      "settings": {
        "auth": "noauth",
        "udp": true,
        "allowTransparent": false
      }
    },
    {
      "tag": "api",
      "port": 10812,
      "listen": "127.0.0.1",
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      }
    }
  ],
  "outbounds": [
    {
      "tag": "proxy",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "tr.boilersforpellets.com",
            "port": 3500,
            "users": [
              {
                "id": "1309f864-b0e9-4567-b169-0410580e04a5",
                "email": "t@t.tt",
                "security": "auto",
                "encryption": "none"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "tcpSettings": {
          "header": {
            "type": "http",
            "request": {
              "version": "1.1",
              "method": "GET",
              "path": [
                "/"
              ],
              "headers": {
                "Host": [],
                "User-Agent": [],
                "Accept-Encoding": [
                  "gzip, deflate"
                ],
                "Connection": [
                  "keep-alive"
                ],
                "Pragma": "no-cache"
              }
            }
          }
        }
      },
      "mux": {
        "enabled": false,
        "concurrency": -1
      }
    },
    {
      "tag": "direct",
      "protocol": "freedom"
    },
    {
      "tag": "block",
      "protocol": "blackhole"
    }
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api"
      },
      {
        "type": "field",
        "outboundTag": "proxy",
        "domain": [
          "domain:googleapis.cn",
          "domain:gstatic.com"
        ]
      },
      {
        "type": "field",
        "port": "443",
        "network": "udp",
        "outboundTag": "block"
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "ip": [
          "geoip:private"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": [
          "geosite:private"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "ip": [
          "223.5.5.5",
          "223.6.6.6",
          "2400:3200::1",
          "2400:3200:baba::1",
          "119.29.29.29",
          "1.12.12.12",
          "120.53.53.53",
          "2402:4e00::",
          "2402:4e00:1::",
          "180.76.76.76",
          "2400:da00::6666",
          "114.114.114.114",
          "114.114.115.115",
          "114.114.114.119",
          "114.114.115.119",
          "114.114.114.110",
          "114.114.115.110",
          "180.184.1.1",
          "180.184.2.2",
          "101.226.4.6",
          "218.30.118.6",
          "123.125.81.6",
          "140.207.198.6",
          "1.2.4.8",
          "210.2.4.8",
          "52.80.66.66",
          "117.50.22.22",
          "2400:7fc0:849e:200::4",
          "2404:c2c0:85d8:901::4",
          "117.50.10.10",
          "52.80.52.52",
          "2400:7fc0:849e:200::8",
          "2404:c2c0:85d8:901::8",
          "117.50.60.30",
          "52.80.60.30"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": [
          "domain:alidns.com",
          "domain:doh.pub",
          "domain:dot.pub",
          "domain:360.cn",
          "domain:onedns.net"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "ip": [
          "geoip:cn"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": [
          "geosite:cn"
        ]
      }
    ]
  },
  "metrics": {
    "tag": "api"
  },
  "policy": {
    "system": {
      "statsOutboundUplink": true,
      "statsOutboundDownlink": true
    }
  },
  "stats": {}
}
EOF

sudo systemctl restart xray
sudo systemctl enable xray
sudo systemctl status xray

curl -x http://127.0.0.1:10808 myip.wtf/json

cat <<EOF | sudo tee -a /etc/dnf/dnf.conf
proxy=http://127.0.0.1:10808
EOF

curl -x http://127.0.0.1:10808 -v https://registry.k8s.io/v2/kube-proxy/manifests/v1.33.5 -H "Accept: application/vnd.docker.distribution.manifest.v2+json"