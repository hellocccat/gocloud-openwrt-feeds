include $(TOPDIR)/rules.mk

PKG_NAME:=ssr-kcptun
PKG_VERSION:=20181002
PKG_RELEASE:=1

PKG_MAINTAINER:=Daniel Fu <xtaci@163.com>
PKG_LICENSE:=MIT

include $(INCLUDE_DIR)/package.mk

define Package/ssr-kcptun
	SECTION:=net
	CATEGORY:=Network
	TITLE:=A Fast & Secure Tunnel Based On KCP with N:M Multiplexing
	URL:=https://github.com/xtaci/kcptun
endef

KCPTUN_ARCH:=
ifeq ($(ARCH),mips)
	KCPTUN_ARCH=mips
else ifeq ($(ARCH),mipsel)
	KCPTUN_ARCH=mipsle
else ifeq ($(ARCH),i386)
	KCPTUN_ARCH=386
else ifeq ($(ARCH),x86_64)
	KCPTUN_ARCH=amd64
else ifeq ($(ARCH),arm)
	KCPTUN_ARCH=arm
endif

define Build/Prepare
	curl -Lo- https://github.com/xtaci/kcptun/releases/download/v$(PKG_VERSION)/kcptun-linux-$(KCPTUN_ARCH)-$(PKG_VERSION).tar.gz | tar zx -C $(PKG_BUILD_DIR)
endef

define Build/Compile
	upx --ultra-brute $(PKG_BUILD_DIR)/client_linux_$(KCPTUN_ARCH)
endef

define Package/ssr-kcptun/install
	$(INSTALL_DIR) $(1)/usr/bin

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/client_linux_$(KCPTUN_ARCH) $(1)/usr/bin/ssr-kcptun
endef

$(eval $(call BuildPackage,ssr-kcptun))
