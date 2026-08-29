import { afterEach, expect } from "vitest";

afterEach(async () => {
  await Promise.all(Array.from(document.fonts, (font) => font.load()));
  await expect(document.documentElement).toMatchScreenshot();
});
