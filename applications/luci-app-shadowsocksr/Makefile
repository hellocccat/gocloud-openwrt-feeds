include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-shadowsocksr
PKG_VERSION:=1.2.1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-shadowsocksr
 	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=shadowsocksr LuCI interface
	DEPENDS:=+shadowsocksr-libev +coreutils +coreutils-base64 +pdnsd +ca-certificates +curl
endef

define Build/Prepare
	$(foreach po,$(wildcard ${CURDIR}/po/zh-cn/*.po), \
		po2lmo $(po) $(PKG_BUILD_DIR)/$(basename $(notdir $(po))).zh-cn.lmo;)
endef

define Build/Compile
endef

define Package/luci-app-shadowsocksr/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/
	cp -pR ./root/* $(1)/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/*.zh-cn.lmo $(1)/usr/lib/lua/luci/i18n/

	find $(1) -name *.lua -exec luac -s -o {} {} \;
endef

define Package/luci-app-shadowsocksr/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	( . /etc/uci-defaults/luci-shadowsocksr ) && rm -f /etc/uci-defaults/luci-shadowsocksr
	rm -f /tmp/luci-indexcache
	chmod 755 /etc/init.d/shadowsocksr >/dev/null 2>&1
	/etc/init.d/shadowsocksr enable >/dev/null 2>&1
fi
exit 0
endef

define Package/luci-app-shadowsocksr/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
     /etc/init.d/shadowsocksr disable
     /etc/init.d/shadowsocksr stop
fi
exit 0
endef

$(eval $(call BuildPackage,luci-app-shadowsocksr))
