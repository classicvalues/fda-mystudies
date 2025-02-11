/*
 * Copyright 2020-2021 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package com.fdahpstudydesigner.util;

import java.awt.Graphics2D;
import java.awt.image.BufferedImage;

public class ImageUtility {

  /**
   * This method is used for to resize the image
   *
   * @param originalImage
   * @param targetWidth
   * @param targetHeight
   * @return
   */
  public static BufferedImage resizeImage(
      BufferedImage originalImage, int targetWidth, int targetHeight) {
    BufferedImage resizedImage =
        new BufferedImage(targetWidth, targetHeight, BufferedImage.TYPE_INT_RGB);
    Graphics2D graphics2D = resizedImage.createGraphics();
    graphics2D.drawImage(originalImage, 0, 0, targetWidth, targetHeight, null);
    graphics2D.dispose();
    return resizedImage;
  }
}
