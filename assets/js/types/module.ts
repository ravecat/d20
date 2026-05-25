export interface ModuleBootstrap {
  endpoint: string;
  topic: string;
  token: string;
}

export interface ModuleEntry {
  id: string;
  title: string;
  embedUrl: string;
  allowedOrigins: string[];
  sandbox: string[];
  bootstrap?: ModuleBootstrap;
}
