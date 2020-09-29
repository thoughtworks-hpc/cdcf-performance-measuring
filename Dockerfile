FROM gcc:8.4.0 AS builder

RUN sed -i "s@http://deb.debian.org@http://mirrors.aliyun.com@g" /etc/apt/sources.list
RUN apt-get clean \
    && apt-get update \
    && apt-get install python-pip cmake vim gdb -y
RUN pip install conan \
    && conan remote add inexorgame "https://api.bintray.com/conan/inexorgame/inexor-conan" \
    && conan remote add hpc "https://api.bintray.com/conan/grandmango/cdcf"

WORKDIR /cdcf-perf-measuring
COPY conanfile.txt .
RUN conan install . -s compiler.libcxx=libstdc++11 --build missing
COPY CMakeLists.txt .
COPY src src
RUN cmake . -DCMAKE_TOOLCHAIN_FILE=conan_paths.cmake -DCMAKE_BUILD_TYPE=Release \
    && cmake --build . -j 3 \
    && ctest --output-on-failure

FROM debian
# Todo: 在debian上安装jdk可能比较费时，看有没有更好的办法
RUN echo "deb http://ftp.us.debian.org/debian sid main" >> /etc/apt/sources.list
RUN apt-get clean \
    && apt-get update \
    && apt-get install wget unzip openjdk-8-jdk -y
COPY --from=builder /cdcf-perf-measuring/bin/cdcf_performance_measuring /bin/cdcf_performance_measuring
WORKDIR /cdcf-perf-measuring
RUN wget https://github.com/undera/perfmon-agent/releases/download/2.2.3/ServerAgent-2.2.3.zip
RUN unzip ServerAgent-2.2.3.zip
COPY docker/agent.sh /bin/agent.sh
COPY docker/run.sh /bin/run.sh

CMD ["/bin/agent.sh"]