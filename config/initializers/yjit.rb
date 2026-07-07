# YJIT is default in rails 7.2, but risks increased memory usage.  Many Haven deployments are on
# memory-constrained devices like small VPSs or Raspberry PIs, so we disable this.
Rails.application.config.yjit = false
