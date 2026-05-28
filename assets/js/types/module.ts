export interface ModuleBootstrap {
  endpoint: string;
  topic: string;
  token: string;
}

export interface ModuleEntry {
  slug: string;
  embedUrl: string;
  allowedOrigins: string[];
  sandbox: string[];
  bootstrap?: ModuleBootstrap;
}
