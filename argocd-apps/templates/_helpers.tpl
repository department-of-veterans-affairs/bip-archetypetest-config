{{/* vim: set filetype=mustache: */}}

{{/*
Template for standard set of global values
*/}}
{{- define "common.global_helm_parameters" -}}
- name: global.deployEnv
  value: {{ .Values.global.deployEnv }}
- name: global.legacyEnv
  value: {{ .Values.global.legacyEnv }}
- name: global.region
  value: {{ .Values.global.region }}
- name: global.accountID
  value: "{{ .Values.global.accountID }}"
- name: global.clusterName
  value: {{ .Values.global.clusterName }}
- name: global.clusterEndpoint
  value: {{ .Values.global.clusterEndpoint }}
- name: global.primaryDomain
  value: {{ .Values.global.primaryDomain }}
- name: global.enableUniqueDomainAsPrimary
  value: "{{ .Values.global.enableUniqueDomainAsPrimary }}"
- name: global.ephemeralCluster
  value: "{{ .Values.global.ephemeralCluster }}"
- name: global.domains.standard
  value: {{ .Values.global.domains.standard }}
- name: global.domains.legacy
  value: {{ .Values.global.domains.legacy }}
- name: global.domains.unique
  value: {{ .Values.global.domains.unique }}
- name: global.domains.lb
  value: {{ .Values.global.domains.lb }}
- name: argocd.app.revision
  value: $ARGOCD_APP_REVISION
- name: global.trustedVACAcert
  value: |
{{ .Values.global.trustedVACAcert | indent 4}}
{{- end -}}