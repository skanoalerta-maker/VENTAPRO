class EmailBaseTemplate {
  static String wrap(String title, String message) {
    return """
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <style>
    body {
      background-color: #0A0A0A;
      color: #FFFFFF;
      font-family: Arial, sans-serif;
      padding: 20px;
    }
    .container {
      max-width: 480px;
      margin: auto;
      margin-left: auto;
      margin-right: auto;
      background: #1A1A1A;
      border-radius: 14px;
      padding: 25px;
      border: 1px solid #333;
    }
    .title {
      font-size: 22px;
      font-weight: bold;
      color: #0A6CFF;
      margin-bottom: 15px;
    }
    .message {
      font-size: 15px;
      line-height: 1.6;
      color: #DDDDDD;
      margin-bottom: 20px;
    }
    .footer {
      margin-top: 30px;
      font-size: 12px;
      color: #888888;
      text-align: center;
    }

    /* Mobile adjustments */
    @media (max-width: 520px) {
      body {
        padding: 10px;
      }
      .container {
        padding: 18px;
      }
      .title {
        font-size: 20px;
      }
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="title">${_safe(title)}</div>
    <div class="message">${_safe(message)}</div>
    <div class="footer">
      SKANO — Seguridad Inteligente<br>
      Correo automático de seguridad. No responda este mensaje.
    </div>
  </div>
</body>
</html>
""";
  }

  static String _safe(String input) {
    return input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
  }
}
