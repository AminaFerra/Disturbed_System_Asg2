# Secure Distributed System

## Overview
This project implements a secure distributed system with load balancing, authentication, asynchronous processing, and full request tracking. It also demonstrates security differences between HTTP and HTTPS using MITM simulation.

## Architecture
Client → Nginx → API1 / API2 / API3 → RabbitMQ → Worker → Database

## Features
- Load balancing (Nginx)
- HTTPS communication
- JWT authentication
- Rate limiting
- Asynchronous processing (RabbitMQ)
- Worker service for task processing
- Audit logging in database
- Request state tracking across services

## Request Flow
1. Client sends request to Nginx (HTTPS)
2. Nginx forwards request to API instance
3. API validates JWT token
4. API generates unique Request ID
5. API sends task to RabbitMQ
6. Worker consumes and processes task
7. All services log state changes in database

## Request States
- RECEIVED
- AUTHENTICATED
- QUEUED
- CONSUMED
- PROCESSED

## MITM Simulation
- HTTP Mode: traffic is readable (headers, JWT, payload visible)
- HTTPS Mode: traffic is encrypted and unreadable

## Run Project
```bash
docker-compose up --build
