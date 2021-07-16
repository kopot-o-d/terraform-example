FROM node:12.13.0-alpine as build
WORKDIR /app

ENV PATH /app/node_modules/.bin:$PATH
ENV TOOL_NODE_FLAGS: --max_old_space_size=4096
COPY frontend/package.json /app/package.json
RUN npm install --no-optional
COPY frontend /app
RUN npm run build

FROM nginx:1.16.0-alpine
COPY --from=build /app/build /usr/share/nginx/html
RUN rm /etc/nginx/conf.d/default.conf
COPY .docker/nginx/nginx.conf /etc/nginx/conf.d
EXPOSE 80
ENTRYPOINT ["nginx", "-g", "daemon off;"]
