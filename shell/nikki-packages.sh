#!/bin/sh

# Download the Nikki feed packages needed by the ImageBuilder image step.
prepare_nikki_packages() {
    branch="$1"
    format="$2"
    feed_arch=$(sed -n 's/^CONFIG_TARGET_ARCH_PACKAGES="\([^"]*\)"/\1/p' .config)
    feed_arch=${feed_arch:-$(sed -n 's/^CONFIG_ARCH="\([^"]*\)"/\1/p' .config)}

    if [ -z "$feed_arch" ]; then
        echo "Error: unable to determine ImageBuilder target architecture"
        return 1
    fi

    feed_url="https://nikkinikki.pages.dev/$branch/$feed_arch/nikki"
    mkdir -p packages
    echo "Downloading Nikki packages for $branch/$feed_arch"

    index_json=$(wget -qO- "$feed_url/index.json") || {
        echo "Error: unable to download Nikki package index: $feed_url/index.json"
        return 1
    }
    index_json=$(printf '%s' "$index_json" | tr -d '\n')

    nikki_version=$(printf '%s' "$index_json" | sed -n 's/.*"nikki"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    mihomo_version=$(printf '%s' "$index_json" | sed -n 's/.*"mihomo-meta"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    luci_version=$(printf '%s' "$index_json" | sed -n 's/.*"luci-app-nikki"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    i18n_version=$(printf '%s' "$index_json" | sed -n 's/.*"luci-i18n-nikki-zh-cn"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

    if [ -z "$nikki_version" ] || [ -z "$mihomo_version" ] || \
        [ -z "$luci_version" ] || [ -z "$i18n_version" ]; then
        echo "Error: Nikki package index is missing a required package version"
        return 1
    fi

    if [ "$format" = "ipk" ]; then
        packages="nikki_${nikki_version}_${feed_arch}.ipk mihomo-meta_${mihomo_version}_${feed_arch}.ipk luci-app-nikki_${luci_version}_all.ipk luci-i18n-nikki-zh-cn_${i18n_version}_all.ipk"
    elif [ "$format" = "apk" ]; then
        packages="nikki-${nikki_version}.apk mihomo-meta-${mihomo_version}.apk luci-app-nikki-${luci_version}.apk luci-i18n-nikki-zh-cn-${i18n_version}.apk"
    else
        echo "Error: unsupported Nikki package format: $format"
        return 1
    fi

    for package_file in $packages; do
        if ! wget -q "$feed_url/$package_file" -P packages; then
            echo "Error: unable to download Nikki package: $feed_url/$package_file"
            return 1
        fi
    done

    NIKKI_PACKAGES="nikki mihomo-meta luci-app-nikki luci-i18n-nikki-zh-cn"
    export NIKKI_PACKAGES
    echo "Nikki packages are ready: $NIKKI_PACKAGES"
}
