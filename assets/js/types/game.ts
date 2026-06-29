export interface GameMetadata {
  name: string | null;
  alternateNames: string[];
  categories: string[];
  mechanics: string[];
  description?: string | null;
  thumbnailUrl?: string | null;
  imageUrl?: string | null;
  yearPublished?: number | null;
  minPlayers?: number | null;
  maxPlayers?: number | null;
  playingTime?: number | null;
  minPlayTime?: number | null;
  maxPlayTime?: number | null;
  minAge?: number | null;
}

export interface GameCatalogEntry {
  slug: string;
  game: GameMetadata;
}

export interface SessionMember {
  online_at: number;
  display_name?: string;
  avatar?: string | null;
}

export interface Session<TGame = unknown> {
  id: string;
  phase: "waiting_for_players" | "in_progress" | "finished";
  owner_id: string;
  members: Record<string, SessionMember>;
  game: TGame;
}
