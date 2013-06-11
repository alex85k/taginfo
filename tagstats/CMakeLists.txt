PROJECT(Tagstats)
cmake_minimum_required(VERSION 2.8.5)

SET(SEARCH_PREFIX "" CACHE PATH "Place where to search additional libraries")

SET(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${SEARCH_PREFIX})

OPTION(BUILD_ALL_STORAGES "try to build all storage variants" 0)

include(FindBoost)
find_package (Boost 1.38 REQUIRED)
MARK_AS_ADVANCED(CLEAR BOOST_ROOT)

INCLUDE (CheckIncludeFiles)
CHECK_INCLUDE_FILES(winsock2.h HAVE_WINSOCK)
if(HAVE_WINSOCK)
   add_definitions( -DD_HAVE_WINSOCK )
   LIST(APPEND WIN_LIBS ws2_32)
endif() 

if(CMAKE_COMPILER_IS_GNUCC AND WIN32)
LIST(APPEND WIN_LIBS iconv)
endif()

if(NOT CMAKE_COMPILER_IS_GNUCC AND WIN32)
   find_path(GETOPT_INCLUDE_DIR getopt.h)
   find_library(GETOPT_LIBRARY NAMES wingetopt )
   if (GETOPT_INCLUDE_DIR AND GETOPT_LIBRARY)
       include_directories(${GETOPT_INCLUDE_DIR})
       LIST(APPEND WIN_LIBS ${GETOPT_LIBRARY})
   endif()
endif()

if(Boost_FOUND)
    include_directories(${Boost_INCLUDE_DIRS})
else()
    set(BOOST_ROOT "NOT FOUND: please choose" CACHE PATH "")
    MESSAGE(FATAL_ERROR "PLEASE, specify the directory where the Boost library is installed in BOOST_ROOT")
endif(Boost_FOUND)

find_package(ZLIB)
if ( ZLIB_FOUND )
    include_directories(${ZLIB_INCLUDE_DIR})
else(ZLIB)
    MARK_AS_ADVANCED(CLEAR ZLIB_LIBRARY ZLIB_INCLUDE_DIR)
    message(FATAL_ERROR "Please, specify the ZLIB includes directory and the library file")
endif( ZLIB_FOUND )

find_package(EXPAT)
if ( EXPAT_FOUND )
    include_directories(${EXPAT_INCLUDE_DIR})
else(EXPAT_FOUND )
    MARK_AS_ADVANCED(CLEAR EXPAT_LIBRARY EXPAT_INCLUDE_DIR)
    message(FATAL_ERROR "Please, specify the EXPAT includes directory and the library file")
endif( EXPAT_FOUND  )

find_package(Protobuf)
if ( PROTOBUF_INCLUDE_DIR AND PROTOBUF_LITE_LIBRARY )
    include_directories(${PROTOBUF_INCLUDE_DIR})
else()
    MARK_AS_ADVANCED(CLEAR PROTOBUF_INCLUDE_DIR PROTOBUF_LITE_LIBRARY )
    message(FATAL_ERROR "Please, specify the Google PROTOBUF library dir")
endif()

##### Find OSMPBF  Library 
find_path(OSMPBF_INCLUDE_DIR osmpbf/osmpbf.h)
find_library(OSMPBF_LIBRARY NAMES osmpbf )
#####

if(OSMPBF_LIBRARY AND OSMPBF_INCLUDE_DIR)
  include_directories(${OSMPBF_INCLUDE_DIR})
  SET(OSMPBF_FOUND 1)
  SET(OSMPBF_LIBRARIES ${OSMPBF_LIBRARY} ${PROTOBUF_LITE_LIBRARY} ${ZLIB_LIBRARY})
  MESSAGE( STATUS "OSMPBF library found")
else()
  MESSAGE( FATAL_ERROR "OSMPBF library not found, please specify its location manually")
endif()

##### Find Google SparseHash
find_path(SPARSEHASH_INCLUDE_DIR google/sparsetable)
if(SPARSEHASH_INCLUDE_DIR)
  MESSAGE( STATUS "SparseHash library found")
  SET(SPARSEHASH_FOUND 1)
else()
  MESSAGE( STATUS "SparseHash library not found, please specify SPARSEHASH_INCLUDE_DIR")
endif()
#####

##### Find GD Library 
find_path(GD_INCLUDE_DIR gd.h REQUIRED)
find_library(GD_LIBRARY NAMES libgd-static gd)
if(GD_INCLUDE_DIR AND GD_LIBRARY)
  SET(GD_FOUND 1)
  find_package(PNG REQUIRED)
  MESSAGE( STATUS "GD library found")
else()
  MESSAGE(FATAL_ERROR "GD library not found, please specify GD_INCLUDE_DIR AND GD_LIBRARY")
endif()
#####

find_path(SQLITE3_INCLUDE_DIR sqlite3.h)
find_library(SQLITE3_LIBRARY NAMES sqlite3 )
if(SQLITE3_INCLUDE_DIR AND SQLITE3_LIBRARY)
  SET(SQLITE3_FOUND 1)
  MESSAGE( STATUS "SQLITE3 library found")
else()
  MESSAGE(FATAL_ERROR "SQLITE3 library not found, please specify SQLITE3_INCLUDE_DIR AND SQLITE3_LIBRARY")
endif()

find_path(OSMIUM_INCLUDE_DIR osmium/osm.hpp)
if(OSMIUM_INCLUDE_DIR)
  SET(OSMIUM_FOUND 1)
  MESSAGE( STATUS "OSMIUM headers found")
else()
  MESSAGE(FATAL_ERROR "OSMIUM headers not found, please specify OSMIUM_INCLUDE_DIR")
endif()

find_package(Threads)

if(WIN32)
	ADD_DEFINITIONS( -DWIN32 -D_WIN32 -DMSWIN32 -DBGDWIN32 -DWINVER=0x0500  -D_WIN32_WINNT=0x0500 -D_WIN32_IE=0x0600)
	set(CPACK_GENERATOR ZIP)
else(WIN32)
	set(CPACK_GENERATOR TGZ)
endif(WIN32)

IF(CMAKE_COMPILER_IS_GNUCC)
    SET(WARNING_FLAGS "-Wall -Wextra -Wredundant-decls -Wdisabled-optimization -pedantic")
    SET(CXX_FLAGS "-O3 -g")
    SET(CMAKE_CXX_FLAGS ${CXX_FLAGS} ${WARNINGS_FLAGS})
ENDIF(CMAKE_COMPILER_IS_GNUCC)



add_definitions(
  -D_LARGEFILE_SOURCE 
  -D_FILE_OFFSET_BITS=64
  -DTAGSTATS_COUNT_USERS 
  -DTAGSTATS_COUNT_KEY_COMBINATIONS 
  -DTAGSTATS_COUNT_TAG_COMBINATIONS )

SET(TAGSTATS_SRC tagstats.cpp string_store.hpp  sqlite.hpp  tagstats_handler.hpp geodistribution.hpp )
SET(OSMSTATS_SRC osmstats.cpp statistics_handler.hpp sqlite.hpp )

include_directories(${OSMIUM_INCLUDE_DIR})
include_directories(${GD_INCLUDE_DIR})
include_directories(${PNG_INCLUDE_DIR})
include_directories(${SQLITE3_INCLUDE_DIR})
include_directories(${EXPAT_INCLUDE_DIR})
include_directories(${OSMPBF_INCLUDE_DIR})
include_directories(${PROTOBUF_INCLUDE_DIR})

if(SPARSEHASH_FOUND)
   include_directories(${SPARSEHASH_INCLUDE_DIR})
endif()

SET(ALL_LIBS ${SQLITE3_LIBRARY} ${GD_LIBRARY} ${PNG_LIBRARIES} 
     ${EXPAT_LIBRARY} ${OSMPBF_LIBRARIES} ${WIN_LIBS} ${CMAKE_THREAD_LIBS_INIT})

add_definitions(-DTAGSTATS_GEODISTRIBUTION_INT=uint16_t)


if(BUILD_ALL_STORAGES) 

SET(STORAGES_IDS
	MmapFile
	SparseMap
	SimpleMap
	SparseTable
	Vector
)

if(NOT WIN32)
list(INSERT STORAGES_IDS 0 MmapAnon)
endif()

FOREACH(BYID ${STORAGES_IDS})
      STRING(REGEX REPLACE "^([A-Z][a-z]*)([A-Z][a-z]*)$" "\\1_\\2" BYID_I ${BYID} )
      STRING(TOLOWER ${BYID_I} BYID_IL )
      SET(BYID_INCL "<osmium/storage/byid/${BYID_IL}.hpp>" )
      MESSAGE("Using ID-storage at " ${BYID_INCL} ", class " ${BYID} )
      SET(TGT tagstats_${BYID})
      add_executable(${TGT} ${TAGSTATS_SRC})
      set_property(TARGET ${TGT} PROPERTY COMPILE_DEFINITIONS 
            TAGSTATS_GEODISTRIBUTION_INCLUDE=${BYID_INCL} TAGSTATS_GEODISTRIBUTION_FOR_WAYS=${BYID})
      target_link_libraries(${TGT} ${ALL_LIBS})
      install(TARGETS ${TGT} RUNTIME DESTINATION ".")
ENDFOREACH()
else()
   SET(BYID "SparseTable" CACHE STRING "Choose storage type, see osmium/storage/byid")
   #set_property(CACHE BYID PROPERTY STRINGS "SparseTable" "Vector" "MmapFile")
 
   STRING(REGEX REPLACE "^([A-Z][a-z]*)([A-Z][a-z]*)$" "\\1_\\2" BYID_I ${BYID} )
   STRING(TOLOWER ${BYID_I} BYID_IL )
   SET(BYID_INCL "<osmium/storage/byid/${BYID_IL}.hpp>" )

   MESSAGE("Using ID-storage at " ${BYID_INCL} ", class " ${BYID} )
   add_executable(tagstats ${TAGSTATS_SRC})
   set_property(TARGET tagstats PROPERTY COMPILE_DEFINITIONS 
         TAGSTATS_GEODISTRIBUTION_INCLUDE=${BYID_INCL} TAGSTATS_GEODISTRIBUTION_FOR_WAYS=${BYID})
   target_link_libraries(tagstats ${ALL_LIBS})
   install(TARGETS tagstats RUNTIME DESTINATION ".")

endif()

add_executable(osmstats ${OSMSTATS_SRC})
target_link_libraries(osmstats ${SQLITE3_LIBRARY} ${EXPAT_LIBRARY} ${OSMPBF_LIBRARIES} ${WIN_LIBS} ${CMAKE_THREAD_LIBS_INIT})

install(TARGETS osmstats RUNTIME DESTINATION ".")


