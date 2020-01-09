#!/bin/sh

#  buildfmk.sh
#  AHKit
#
#  Created by Sun Honglin on 17/2/13.
#  Copyright © 2017年 AutoHome. All rights reserved.

# Sets the target folders and the final framework product.
# 如果工程名称和Framework的Target名称不一样的话，要自定义FMKNAME
# 例如: FMK_NAME = "MyFramework"
show_usage="可使用参数: [-a , -d , -s , -h][--help]"

function showUsage() {
	echo $show_usage
	echo "使用方式如下: "
	echo "   -a 编译所有, 模拟器+设备, 并合成"
	echo "   -d 只编译设备"
	echo "   -s 只编译模拟器"
	echo "   -h (--help) 显示帮助"
	echo " "
	echo "例如: ./buildfmk.sh -a"
	echo " "
}

COMPILE_MODE="ALL"
for arg in $@
do
	echo "* args $((i++)): $arg *"
done
isArgsHelp=(false)
# 获取解析各个参数值, 并给变量赋值
while true
do
		case "$1" in
				-a)
					COMPILE_MODE="ALL"
					echo "-a) 全编译 ${COMPILE_MODE}"
					shift
					break
					;;
				-d)
					COMPILE_MODE="DEVICE"
					echo "-d) 编译真机 ${COMPILE_MODE}"
					shift
					break
					;;
				-s)
					COMPILE_MODE="SIMULATOR"
					echo "-s) 编译模拟器 ${COMPILE_MODE}"
					shift
					break
					;;
				-h|--help)
					echo "-h|--help)"
					isArgsHelp=true
					showUsage
					exit 0
					shift
					break
					;;
				*)
					echo "*) case end"
					COMPILE_MODE="ALL"
					echo "*) COMPILE_MODE: ${COMPILE_MODE}"
					break
					;;
		esac
done

# ----------- 正式编译步骤 ----------- #
FMK_NAME=${PROJECT_NAME}
echo "*FMK_NAME: \"${FMK_NAME}\""

# 定义最终合并输出路径
# 当前工程的 root 下创建合并的 framework 文件
INSTALL_DIR=${SRCROOT}/Products/${FMK_NAME}.framework
echo "*INSTALL_DIR: \"${INSTALL_DIR}\""

# 定义文件目录: build 目录, 设备 framework 目录, i386framework 目录
WRK_DIR=build
DEVICE_DIR=${WRK_DIR}/Release-iphoneos/${FMK_NAME}.framework
SIMULATOR_DIR=${WRK_DIR}/Release-iphonesimulator/${FMK_NAME}.framework
echo "*DEVICE_DIR: \"${DEVICE_DIR}\""
echo "*SIMULATOR_DIR: \"${SIMULATOR_DIR}\""

# -configuration ${CONFIGURATION}
# 分别编译新的 i386 和 设备 的 framework 文件
xcodebuild -configuration "Release" -target "${FMK_NAME} iOS" clean
if [[ ${COMPILE_MODE} = "DEVICE" || ${COMPILE_MODE} = "ALL" ]]; then
	xcodebuild -configuration "Release" -target "${FMK_NAME} iOS" -sdk iphoneos build
fi

if [[ ${COMPILE_MODE} = "SIMULATOR" || ${COMPILE_MODE} = "ALL" ]]; then
	xcodebuild -configuration "Release" -target "${FMK_NAME} iOS" -sdk iphonesimulator build
fi


# 移除合并过的 framework 文件
if [[ -d "${INSTALL_DIR}" ]];then
rm -rf "${INSTALL_DIR}"
fi

# 创建合并文件夹
mkdir -p "${INSTALL_DIR}"

if [[ ${COMPILE_MODE} = "DEVICE" || ${COMPILE_MODE} = "ALL" ]]; then
	# 以设备 framework 包为基础, 复制包内文件到目标路径, 用来当最终合并的文件的模板
	cp -R "${DEVICE_DIR}/" "${INSTALL_DIR}/"
else
	cp -R "${SIMULATOR_DIR}/" "${INSTALL_DIR}/"
fi


# 用 Lipo Tool 合并 (i386 + armv6/armv7) 的 framework 文件 为单一文件
if [[ ${COMPILE_MODE} = "ALL" ]]; then
	lipo -create "${DEVICE_DIR}/${FMK_NAME}" "${SIMULATOR_DIR}/${FMK_NAME}" -output "${INSTALL_DIR}/${FMK_NAME}"
fi

if [[ $? -ne 0 ]]; then
	echo "*** 编译${FMK_NAME} Framework 失败: lipo 失败 ***";
	exit 1;
fi

# 根据需要自行放开 打开输出 framework 的文件夹, debug 用
# open "${INSTALL_DIR}"
