const size_t CHUNK_SIZE = 2048;  // Experiment with 1024 or 2048 bytes

size_t _jpg_buf_len = 0;
uint8_t *_jpg_buf = NULL;

void send_image(BluetoothSerial &SerialBT) {
  Serial.println("--------------");
  Serial.println("Capturing image...");

#ifdef CAMERA_MODEL_WROVER_KIT
  // Flush stale frame
  camera_fb_t *flush_fb = esp_camera_fb_get();
  if (flush_fb) esp_camera_fb_return(flush_fb);
  delay(200);  // allow fresh frame capture
#endif

  camera_fb_t *fb = esp_camera_fb_get();
  if (!fb) {
    digitalWrite(ONBOARD_LED, !TURN_ON);
    Serial.println("[CAM]: esp_camera_fb_get() failed!");
    ESP.restart();
    return;
  }

  Serial.println("Image captured.");

  uint16_t width = fb->width;
  uint16_t height = fb->height;

  if (fb->format != PIXFORMAT_JPEG) {
    // Compress with JPEG
    Serial.println("JPEG Compressing...");
    bool jpeg_converted = frame2jpg(fb, 80, &_jpg_buf, &_jpg_buf_len);
    esp_camera_fb_return(fb);
    fb = NULL;
    if (!jpeg_converted) {
      Serial.println("JPEG compression failed");
      return;
    }
  } else {
    _jpg_buf_len = fb->len;
    _jpg_buf = fb->buf;
  }

  Serial.print("w: ");
  Serial.print(width);
  Serial.print(", ");
  Serial.print("h: ");
  Serial.println(height);
  Serial.print("size: ");
  Serial.println(_jpg_buf_len);

  Serial.println("Sending image...");

  uint8_t startMarker[4] = START_MARKER;
  uint8_t endMarker[4] = END_MARKER;

  //========================================================

  SerialBT.write(startMarker, 4);
  SerialBT.write((uint8_t *)&_jpg_buf_len, 4);  // image size (4 bytes)
  SerialBT.write((uint8_t *)&width, 2);         // width (2 bytes)
  SerialBT.write((uint8_t *)&height, 2);        // height (2 bytes)

  // Send data in chunks
  size_t bytesSent = 0;
  while (bytesSent < _jpg_buf_len) {
    size_t chunk = min(CHUNK_SIZE, (size_t)(_jpg_buf_len - bytesSent));
    SerialBT.write(_jpg_buf + bytesSent, chunk);
    // SerialBT.flush();  // Helps push out buffered data
    bytesSent += chunk;

    delay(0);
  }

  SerialBT.write(endMarker, 4);

  //========================================================

  if (fb) {
    esp_camera_fb_return(fb);
    _jpg_buf = NULL;
  } else if (_jpg_buf) {
    free(_jpg_buf);
    _jpg_buf = NULL;
  }

  Serial.println("Image sent.");
}

void handle_cam_stream(BluetoothSerial &SerialBT) {
  if (SerialBT.hasClient()) {
    if (SerialBT.available()) {
      String cmd = SerialBT.readStringUntil('\n');
      cmd.trim();

      if (cmd == COMMAND_CAP) {
        Serial.println("[CAM_STREAM]: CAP detected.");
        send_image(SerialBT);
      } else {
        Serial.println("[CAM_STREAM]: Unknown command!");
      }
    }
  }
}