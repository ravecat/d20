import { afterEach, expect } from "vitest";

afterEach(async () => {
  await expect(document.documentElement).toMatchScreenshot();
});
