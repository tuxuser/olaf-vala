cmake_minimum_required(VERSION 3.0)
list(APPEND CMAKE_MODULE_PATH
    ${CMAKE_SOURCE_DIR}/cmake/vala
)

set(CMAKE_CXX_FLAGS_TEST "-Ofast")
set(CMAKE_C_FLAGS_TEST "-Ofast -funroll-loops -fprefetch-loop-arrays -march=native")

if(CMAKE_BUILD_TYPE STREQUAL "")
	set(CMAKE_BUILD_TYPE "Debug")
endif(CMAKE_BUILD_TYPE STREQUAL "")

include(FindVala)
include(UseVala)

## Temporarly use in-tree build of vala
#set(VALA_EXECUTABLE ${CMAKE_SOURCE_DIR}/vala/build/compiler/valac${CMAKE_EXECUTABLE_SUFFIX})
#set(VALA_FLAGS
#    --vapidir ${CMAKE_SOURCE_DIR}/vala/vapi
#)

find_package(Vala REQUIRED)

find_package(PkgConfig REQUIRED)
pkg_check_modules(GLIB2 REQUIRED glib-2.0>=2.38)
pkg_check_modules(GIO2 REQUIRED gio-2.0)
pkg_check_modules(GOBJECT2 REQUIRED gobject-2.0>=2.38)
pkg_check_modules(GEE REQUIRED gee-0.8)
pkg_check_modules(LIBUSB REQUIRED libusb-1.0)
pkg_check_modules(LIBSERIALPORT REQUIRED libserialport)

find_library(GCRYPT_LIBRARY gcrypt)

if(CMAKE_COMPILER_IS_GNUCC)
	add_definitions(-Wno-discarded-qualifiers)
endif()

file(GLOB_RECURSE source_list RELATIVE "${CMAKE_SOURCE_DIR}" "src/*.vala")
file(GLOB_RECURSE VAPI_LIST RELATIVE "${CMAKE_SOURCE_DIR}" "vapi/*.vapi")

#if(UNIX)
#	list(REMOVE_ITEM source_list
#		src/Communication/Serial.vala
#	)
#	list(REMOVE_ITEM VAPI_LIST
#		vapi/WindowsCom.vapi
#	)
#else()
#	add_subdirectory(native)
#	include_directories(native/WindowsCom)
#endif()

message(STATUS "Found Sources: ${source_list}")
message(STATUS "Found VAPIs: ${VAPI_LIST}")

set(valac_flags "-g")

if(MINGW)
	list(APPEND valac_flags -D MINGW)
elseif(WIN32)
	list(APPEND valac_flags -D WIN32)
endif()

vala_precompile(VALA_C
	${source_list}
DIRECTORY
	${CMAKE_BINARY_DIR}
PACKAGES
    gio-2.0
    posix
    gee-0.8
	libusb-1.0
OPTIONS
    --disable-warnings
    --thread
    #-g
    ${valac_flags}
    ${VALA_FLAGS}
CUSTOM_VAPIS
    ${VAPI_LIST}
GENERATE_VAPI
    olaf
GENERATE_HEADER
    olaf
)

include_directories(
    ${GLIB2_INCLUDE_DIRS}
    ${GIO2_INCLUDE_DIRS}
    ${GOBJECT2_INCLUDE_DIRS}
    ${GEE_INCLUDE_DIRS}
	${LIBUSB_INCLUDE_DIRS}
	${LIBSERIALPORT_INCLUDE_DIRS}
)

link_directories(
    ${GLIB2_LIBRARY_DIRS}
    ${GIO2_LIBRARY_DIRS}
    ${GOBJECT2_LIBRARY_DIRS}
    ${GEE_LIBRARY_DIRS}
	${LIBUSB_LIBRARY_DIRS}
	${LIBSERIALPORT_LIBRARY_DIRS}
)

add_executable(olaf ${VALA_C})

include_directories(native/headers)
#include_directories(native/libmfile)

set(olaf_libs
    ${GLIB2_LIBRARIES}
    ${GIO2_LIBRARIES}
    ${GOBJECT2_LIBRARIES}
    ${GEE_LIBRARIES}
	${LIBUSB_LIBRARIES}
	${GCRYPT_LIBRARY}
	${LIBSERIALPORT_LIBRARIES}
)


if(MINGW AND DEBUG)
	find_library(ExcHndl exchndl)
	list(APPEND olaf_libs ${ExcHndl})
elseif(UNIX)
	find_library(liblm m)
	list(APPEND olaf_libs ${liblm})
endif()

if(WIN32)
#	list(APPEND olaf_libs WindowsCom)
endif()

target_link_libraries(olaf ${olaf_libs})

macro(build_cv2pdb)
	set(CV2PDB_DIR ${CMAKE_SOURCE_DIR}/cv2pdb)
	#set(CV2PDB_OUTDIR ${CV2PDB_DIR}/bin/${CMAKE_BUILD_TYPE})
	set(CV2PDB_OUTDIR ${CV2PDB_DIR}/bin)
	set(CV2PDB_EXE ${CV2PDB_OUTDIR}/cv2pdb${CMAKE_EXECUTABLE_SUFFIX})

	# Create a build directory for cv2pdb
	add_custom_target(cv2pdb-make-directory
		ALL
		COMMAND ${CMAKE_COMMAND} -E make_directory ${CV2PDB_OUTDIR}
	)

	add_custom_command(
		DEPENDS cv2pdb-make-directory
		OUTPUT ${CV2PDB_EXE}
		COMMAND ${CMAKE_COMMAND} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} ${CV2PDB_DIR}
		COMMAND ${CMAKE_COMMAND} --build .
		WORKING_DIRECTORY ${CV2PDB_OUTDIR}
		COMMENT "Building cv2pdb"
		VERBATIM
	)

	add_custom_target(cv2pdb ALL DEPENDS ${CV2PDB_EXE})
endmacro()

function(run_cv2pdb target exe)
	
	add_custom_command(
		#OUTPUT ${exe}
		TARGET ${target}
		POST_BUILD
		COMMAND cmd //C ${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunAsDev.bat ${CV2PDB_EXE} -C ${exe} ${exe}
		COMMENT "Running cv2pdb for ${target}"
		VERBATIM
	)
	
	#add_custom_target(cv2pdb_${target} ALL DEPENDS ${exe})
	
endfunction()

if(MINGW AND PDB)
		build_cv2pdb()
		
		#get_target_property(olafExe olaf RUNTIME_OUTPUT_DIRECTORY)
		#set(olafExe "${olafExe}/olaf${CMAKE_EXECUTABLE_SUFFIX}")
		run_cv2pdb(olaf $<TARGET_FILE:olaf>)
endif()

#add_subdirectory(tools)
