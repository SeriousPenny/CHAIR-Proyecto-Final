# Proyecto final de Grado: CHAIR
Este es mi proyecto final del Grado Superior de Desarrollo de Aplicaciones Multiplataformas. Se trata de una plataforma de distribución de videojuegos (ej.: Steam, Origin, Epic Games, etc.) en la que puedes:

- Registrarte
- Logearte
- Crearte un perfil y cambiar tu descripción
- Mirar la tienda y encontrar juegos que te gusten
- Descargar los juegos con solo un clic
- Lanzar los juegos desde la misma aplicación
- Automáticamente te registra las horas que has jugado cada juego
- Añadir amigos y ver sus perfiles
- Ver qué amigos están en línea y qué están jugando
- Ver tu lista de amigos y chatear con ellos en tiempo real
- Ver qué juegos juegan tus amigos
- Cambiar opciones de la aplicación como:
  - Activar o desactivar los sonidos de notificación
  - Minimizar a la bandeja cuando le das a la X
  - Carpeta de tus juegos (si cambias la carpeta te detecta automáticamente si hay juegos instalados ahí)
- Cambiar tus datos
  - Puedes cambiar tu descripción
  - Tu localización
  - Cambiar tu contraseña
  - Poner tu perfil en privado
- Si eres admin, puedes:
  - Ver estadísticas en tiempo real de los juegos (número de descargas, jugadores jugando, y total de horas jugadas acumuladas)
  - Banear usuarios, ya sea por nombre de usuario o por IP
  - Perdonar baneos de usuarios
  - Añadir nuevos juegos a la tienda
  - Cambiar el juego principal de la tienda

Por desgracia, para que funcione de verdad haría falta tener un servidor dedicado que corra el servidor y la API. Como no dispongo de tal, no es posible probarlo, pero todo el código se encuentra ahí. Lo máximo que puedo hacer si queréis ver cómo es funcionando es que entréis al siguiente enlace donde hay algunas screenshots de la aplicación en funcionamiento: https://drive.google.com/file/d/1tzWXCpHQJTIEbWpdIEOsBQJJD57T5XQw/view?usp=sharing

Existen 4 carpetas:
- CHAIR: El cliente hecho en WPF con el patrón MVVM
- CHAIRAPI: La API hecha en .NET Core
- CHAIRSignalR: El servidor hecho en .NET Framework con la librería de SignalR
- CHAIRDB: Los scripts de la BBDD de SQL Server
