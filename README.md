# flask-docker-celery-rabbitmq-nginx-gunicorn

This repository is for running a simple dummy flask application in a docker environment.

It uses:
- Flask
- Celery
- Flower
- Rabbitmq
- PostgreSQL (not doing anything, though)
- Nginx
- Gunicorn


## Prerequisites
Make sure you have docker and docker-compose installed.

## Running
Clone this repository and navigate into it in your terminal.
Run in development mode, so set APP_ENV environment to Dev

    APP_ENV=Dev docker-compose up --build

It will expose 2 ports, one for the flask application (8888) and one for the RabbitMQ management interface (15672).
It will also start 2 worker containers.

When it runs, you can test it with several curl posts request and check it running in the Flower interface.

    for value in {1..50}
    do
        curl --data '{json}' -H 'Content-Type: application/json' 0.0.0.0:8888/api/process_data
    done

This will run 50 tasks, you can see in the flower [http://localhost:5555](http://0.0.0.0:5555/)
how the tasks are distributed between the worker instances. Plus, you can run tasks by executing stress.sh

You can also check the status of a specific task in flask:
[http://localhost:8888/api/tasks/\<task-id\>](http://0.0.0.0:8888/api/tasks/<task-id>) 

The RabbitMQ interface [http://localhost:15673](http://0.0.0.0:15673/) with login:
- username: rabbit_user
- password: rabbit_password

## 핵심 내용
![image](https://user-images.githubusercontent.com/57928967/214968366-7f05b578-8e4c-403a-8a96-393731b179a2.png)

* 주어진 그림과 같이 프로토콜을 통해 요청이 어떤 방식으로 프로세스에게 전달되는 지 이해하기
* 하나의 컨테이너 내부에서 마스터 프로세스와 워커 프로세스가 어떤 방식으로 작동하는 지 이해하기
* docker compose를 통해서 컨테이너를 실행한 뒤에 stress.sh 스크립트를 통해 전달된 요청이 어떻게 비동치 처리 되는지 이해하기
    * stress.sh를 통해 nginx로 api(HTTP) 요청 전달
    * nginx 내부의 워커 프로세스의 태스크 큐로 os가 해당 요청을 전달
    * 워커 프로세스가 해당 요청이 정적 요청인지 동적 요청인지 판단한 뒤에 필요할 시에 WAS 서버로 요청 전달(HTTP)
    * Gunicorn의 마스터 프로세스가 HTTP 요청을 WSGI 요청으로 변환한 뒤에 해당 요청을 워커 프로세스에게 전달
    * 워커 프로세스는 비동기 처리가 필요할 시에 AMQP 프로토콜을 통해 RabbitMQ에게 메세지를 전달
    * RabbitMQ는 Celery에게 메세지를 전달
    * Celery의 태스크큐에 메세지가 전달되면, Celery 내부에 있는 워커 프로세스에게 해당 메세지가 전달
    * 최종적으로 Celery의 워커 프로세스가 해당 메세지를 처리
    * 이때 클라이언트는 곧바로 해당 태스크가 시작됐음을 알리는 태스크 아이디만을 반환 받음
    * 이후에 태스크 아이디를 통해서 결과값을 조회하도록 만들 수 있음
