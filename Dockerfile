#実行
FROM ubuntu:16.04

ENV SERVER_PATH=/var/phoenix
ENV SERVER_NAME=server

RUN apt-get update && apt-get install -y wget && wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && dpkg -i erlang-solutions_1.0_all.deb && apt-get update && apt-get install -y esl-erlang && apt-get install -y elixir
RUN apt-get -y install language-pack-ja-base language-pack-ja ibus-mozc && locale-gen && apt-get -y install tzdata && cp /etc/localtime /etc/localtime.org && ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
#RUN apt-get install -y nodejs
#RUN apt-get install -y lsb-release && RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main"' > /etc/apt/sources.list.d/pgdg.list && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add && apt-get update && apt-get upgrade && apt-get install postgresql-9.5 pgadmin3 -y
RUN apt-get -y install nodejs-legacy && apt-get -y install npm && apt-get -y install postgresql && apt-get -y install inotify-tools

#この1行は、Phoenix用のディレクトリ構成を作成するために使用 → ディレクトリをローカルにコピーしてDockerbuild時にコピーし戻している
#RUN mkdir -p ${SERVER_PATH} && cd ${SERVER_PATH} && export LC_ALL=ja_JP.UTF-8 && mix phx.new ${SERVER_NAME} --force && mix local.rebar --force

RUN mkdir -p ${SERVER_PATH}

# COPYの振る舞いについて、本家のドキュメントを参照のこと(以下抜粋)
# https://docs.docker.com/engine/reference/builder/#copy
# If <src> is a directory, the entire contents of the directory are copied, including filesystem metadata.
# Note: The directory itself is not copied, just its contents.
COPY server ${SERVER_PATH}/${SERVER_NAME}

COPY run.sh ${SERVER_PATH}
RUN chmod +x ${SERVER_PATH}/run.sh

USER postgres
RUN service postgresql start && psql --command "alter role postgres with password 'postgres';" && psql --command "UPDATE pg_database SET datistemplate=FALSE WHERE datname='template1';" && psql --command "DROP DATABASE template1;" && psql --command "CREATE DATABASE template1 WITH TEMPLATE=template0 ENCODING='UTF8' LC_COLLATE='ja_JP.UTF-8' LC_CTYPE = 'ja_JP.UTF-8';" && psql --command "UPDATE pg_database SET datistemplate=TRUE WHERE datname='template1';"
RUN export LC_ALL=ja_JP.UTF-8 && mix local.hex --force && mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new.ez --force
RUN service postgresql start && export LC_ALL=ja_JP.UTF-8 && cd ${SERVER_PATH}/${SERVER_NAME} && mix ecto.create && cd assets && npm install

EXPOSE 4000

ENTRYPOINT ${SERVER_PATH}/run.sh

# 作成と起動
# docker build -t peke2/phoenix:1.0 .
# docker run -d -p 4000:4000 peke2/phoenix:1.0
