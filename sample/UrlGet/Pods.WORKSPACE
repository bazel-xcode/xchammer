
new_pod_repository(
  name = "PINOperation",
  url = "https://github.com/pinterest/PINOperation/archive/1.1.zip",
  owner = "@ios-cx",
)

new_pod_repository(
  name = "PINCache",
  url = "https://github.com/pinterest/PINCache/archive/f9f1e551d6a78d74f5528e43a8575f9d2d329e7d.zip",
  owner = "@ios-cx",
)

new_pod_repository(
    name = "GoogleAppIndexing",
    url = "https://www.gstatic.com/cpdc/73945bc162817f93-GoogleAppIndexing-2.0.1.tar.gz",
    podspec_url = "Vendor/PodSpecs/GoogleAppIndexing-2.0.1/GoogleAppIndexing.podspec.json",
    owner = "@javery",
    inhibit_warnings = True,
)

new_pod_repository(
    name = "Weixin", #WeChat
    url = "https://res.wx.qq.com/open/zh_CN/htmledition/res/dev/download/sdk/WeChatSDK1.6.2.zip",
    podspec_url = "Vendor/PodSpecs/Weixin-1.6.2/Weixin.podspec.json",
    owner = "@ios-growth",
    inhibit_warnings = True,

    # Missing type decls
    generate_module_map = False
)

new_pod_repository(
  name = "Stripe",
  url = "https://github.com/stripe/stripe-ios/archive/v10.0.1.zip",
  owner = "@ios-action",
  inhibit_warnings = True,

  # Duplicate interface definition issue
  generate_module_map = False,

  install_script = """
    # XcodeGen workaround
    # https://github.com/yonaskolb/XcodeGen/issues/143
    mkdir Stripe/Resources/Localizations/Base.lproj/
    touch Stripe/Resources/Localizations/Base.lproj/Localizable.strings
    __INIT_REPO__
  """
)

