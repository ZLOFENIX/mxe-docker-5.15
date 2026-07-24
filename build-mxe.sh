#!/bin/bash
set -e

cd /opt/mxe

# Убираем SQL-плагины (mariadb/freetds/postgresql)
sed -i '/-plugin-sql-mysql\|-plugin-sql-psql\|-plugin-sql-tds\|Q_USE_SYBASE/d' src/qtbase.mk
sed -i 's/mariadb-connector-c//;s/freetds//;s/postgresql//' src/qtbase.mk

# 1. Toolchain
make cc MXE_TARGETS='i686-w64-mingw32.shared' JOBS=$(nproc)
rm -rf /opt/mxe/tmp-*

# 2. Meson wrapper
make meson-wrapper MXE_TARGETS='i686-w64-mingw32.shared' JOBS=$(nproc)
rm -rf /opt/mxe/tmp-*

# 3. Зависимости qtbase
make freetype fontconfig harfbuzz dbus icu4c openssl pcre2 \
    MXE_TARGETS='i686-w64-mingw32.shared' JOBS=$(nproc)
rm -rf /opt/mxe/tmp-*

# 4. Qt base
make qtbase MXE_TARGETS='i686-w64-mingw32.shared' JOBS=$(nproc)
rm -rf /opt/mxe/tmp-*

# 5. Лёгкие модули
make qttools qtimageformats qtwinextras \
    MXE_TARGETS='i686-w64-mingw32.shared' JOBS=$(nproc)
rm -rf /opt/mxe/tmp-*

# 6. QML и Quick
make qtdeclarative qtquickcontrols qtquickcontrols2 \
    MXE_TARGETS='i686-w64-mingw32.shared' JOBS=$(nproc)
rm -rf /opt/mxe/tmp-*

# 7. Зависимости WebKit
make libxml2 libxslt libwebp qtmultimedia qtsensors qtwebchannel \
    MXE_TARGETS='i686-w64-mingw32.shared' JOBS=$(nproc)
rm -rf /opt/mxe/tmp-*

# Патчим qtwebkit.mk: вставляем Ruby-фикс в начало сборки
sed -i "/define \$(PKG)_BUILD_SHARED/a\\    sed -i '1i class Object; def =~(other); nil; end; end' '\$(1)/Source/JavaScriptCore/offlineasm/parser.rb'" /opt/mxe/src/qtwebkit.mk

# 8. WebKit — не фатально
set +e
make qtwebkit MXE_TARGETS='i686-w64-mingw32.shared' JOBS=$(nproc)
WEBKIT_EXIT=$?
set -e
rm -rf /opt/mxe/tmp-*

if [ $WEBKIT_EXIT -ne 0 ]; then
    echo "============================================"
    echo "WARNING: QtWebKit failed (exit $WEBKIT_EXIT)"
    echo "Full log: /opt/mxe/log/qtwebkit_i686-w64-mingw32.shared"
    echo "============================================"
fi

# Cleanup (log НЕ удаляем — нужен для артефакта)
rm -rf /opt/mxe/pkg /opt/mxe/.git
