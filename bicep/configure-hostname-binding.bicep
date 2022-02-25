param webAppName string
param certificateThumbprint string
param dnsZoneName string
param hostNameSegment string


resource WebAppHostNamWebAppHostNameBindingSslEnabled 'Microsoft.Web/sites/hostNameBindings@2021-03-01' = {
  name: '${webAppName}/${hostNameSegment}.${dnsZoneName}'
  properties: {
    sslState: 'SniEnabled'
    hostNameType: 'Managed'
    thumbprint: certificateThumbprint
  }
}

