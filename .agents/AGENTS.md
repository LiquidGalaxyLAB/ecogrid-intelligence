# Liquid Galaxy Specific Rules

- **KML Deployment via SSH**: NEVER change the mechanism used for sending KMLs via SSH (`_deployKml` and `atomicUploadText` pipelines). The current atomic upload approach is verified to work perfectly on physical LG hardware (the "Spain setup"). Do not attempt to refactor, simplify, or modify this delivery logic without explicit user override.
