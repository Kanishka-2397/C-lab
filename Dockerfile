FROM node:18
WORKDIR /app
COPY ./package.json .
RUN rpm install
COPY ./app
EXPOSE 3000
ENV DB
CMD ["node","app"]
