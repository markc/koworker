cmake_minimum_required(VERSION 3.21)
project(koworker VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick QuickControls2 Network Sql)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(koworker
    src/main.cpp
)

qt_add_qml_module(koworker
    URI Koworker
    VERSION 1.0
    SOURCES
        src/MessageModel.h src/MessageModel.cpp
    QML_FILES
        qml/Main.qml
        qml/ChatView.qml
        qml/MessageDelegate.qml
        qml/Theme.qml
)

target_include_directories(koworker PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_link_libraries(koworker PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Network
    Qt6::Sql
)
