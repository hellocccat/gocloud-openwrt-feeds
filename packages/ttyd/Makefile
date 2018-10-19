#
# Copyright (C) 2016 Shuanglei Tao <tsl0922@gmail.com>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=ttyd
PKG_VERSION:=1.4.2
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_PROTO:=git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_URL:=https://github.com/tsl0922/ttyd.git
PKG_SOURCE_VERSION:=$(PKG_VERSION)

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

CMAKE_INSTALL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/ttyd
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=Command-line tool for sharing terminal over the web
	DEPENDS:=+libopenssl +libjson-c +libpthread +libwebsockets-openssl
	URL:=https://github.com/tsl0922/ttyd
	SUBMENU:=Terminal
	MAINTAINER:=Shuanglei Tao <tsl0922@gmail.com>
endef

define Package/ttyd/description
ttyd is a command-line tool for sharing terminal over the web.
endef

define Package/ttyd/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/ttyd $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./root/etc/init.d/ttyd $(1)/etc/init.d/ttyd
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./luci/controller/terminal.lua $(1)/usr/lib/lua/luci/controller/terminal.lua
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view
	$(INSTALL_DATA) ./luci/view/terminal.htm $(1)/usr/lib/lua/luci/view/terminal.htm
endef

define Package/ttyd/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	/etc/init.d/ttyd disable
	/etc/init.d/ttyd stop
fi
endef

$(eval $(call BuildPackage,ttyd))
