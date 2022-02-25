param location string
param dnsZoneName string
param hostNameSegment string

var uniqueIdentifier = uniqueString(subscription().subscriptionId, resourceGroup().name)

resource DnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: dnsZoneName
}

resource AppServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: '${uniqueIdentifier}-asp'
  location: location
  sku: {
    name: 'B1'
  }
  kind: 'linux'
}

resource WebApp 'Microsoft.Web/sites@2021-03-01' = {
  name: '${uniqueIdentifier}-app'
  location: location
  properties: {
    serverFarmId: AppServicePlan.id
    siteConfig: {
      netFrameworkVersion: '6.0'
    }
  }
}

resource DnsVerificationTxtRecord 'Microsoft.Network/dnsZones/TXT@2018-05-01' = {
  name: 'asuid.${hostNameSegment}'
  parent: DnsZone
  properties: {
    TTL: 30
    TXTRecords: [
      {
        value: [
          WebApp.properties.customDomainVerificationId
        ]
      }
    ]
  }
}

resource DnsRecord 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  name: hostNameSegment
  parent: DnsZone
  properties: {
    TTL: 30
    CNAMERecord: {
      cname: WebApp.properties.defaultHostName
    }
  }
}


resource WebAppHostNameBindingSslDisabled 'Microsoft.Web/sites/hostNameBindings@2021-03-01' = {
  name: '${WebApp.name}/${hostNameSegment}.${dnsZoneName}'
  properties: {
  }
  dependsOn: [
    DnsVerificationTxtRecord
  ]
}

resource WebAppCertificate 'Microsoft.Web/certificates@2021-03-01' = {
  location: location
  name: '${hostNameSegment}.${dnsZoneName}'
  properties: {
    canonicalName: '${hostNameSegment}.${dnsZoneName}'
    hostNames: [
      '${hostNameSegment}.${dnsZoneName}'
    ]
    serverFarmId: AppServicePlan.id
  }
  dependsOn: [
    WebAppHostNameBindingSslDisabled
    DnsRecord
  ]
}

module EnableSslBinding 'configure-hostname-binding.bicep' = {
  name: 'enable-ssl-binding'
  params: {
    certificateThumbprint: WebAppCertificate.properties.thumbprint
    dnsZoneName: dnsZoneName
    hostNameSegment: hostNameSegment
    webAppName: WebApp.name
  }
}

