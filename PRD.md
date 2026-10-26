# Funtionality.

This is a social network links saver. The entire site is the spanish languaje. It is a website that will save links that has categories.

It has the capability of saving different links, like, youtube, facebook, instagram, tiktok.

For instance:

Category: IA
Sub Category (Optional): OCR
Link Type: Youtube
Link: https://www.youtube.com/shorts/KigUHSCgDNo
Short Description: AI Creator Studio
Long Description: Es un video corto que indica todos los pasos para crear videos para youtube con transcripciones, lenguajes diferentes usando diferentes aplicaciones existentes en internet, generando un estudio de creacion de videos para diferentes cosas
Artifact: PDF or other relevant file optional.

# Technical Specification.

This is a Phoenix using ASH Framework Elixir PWA Web Software. It saves files inside the project in a folder called artifacts/. Also it works with a simple sqlite database.

* It has to use Ash Framework
* Elixir.

For any specific documentation, refers to context7 MCP or find over internet.

In this home computer we have the following versions:

  • Phoenix installer (phx.new): v1.8.4
  • Elixir: 1.18.2 (compiled with Erlang/OTP 27)
  • Erlang/OTP: 27 (erts-15.2.2)

The idea is to create a docker-compose.yml version of the sofware and it will works in my asus network computer.

## Web Specifications.

* It has to be 100% Mobile First.
* PWA Ready installable.
* Phoenix LiveView with Tailwind CSS + DaisyUI.
* 3 Themes Selectors so it need to concentrate the the themes like a professional software solution.

## Login.

The login is a simple as 4 pin access like a phone numbers to type with clicks, PIN: 8751

## Scheduler.

An internal Elixir scheduler (e.g., Oban or Quantum with `tzdata`) to save/backup the SQLite database every day at 1:00 AM.

## Date Time.

Works always with America/Santiago hour date time.


