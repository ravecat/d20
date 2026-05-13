export interface GameMetadata {
  externalId?: number;
  slug: string;
  name: string;
  alternateNames: string[];
  description: string;
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

export interface SessionMember {
  online_at: number;
}

export interface Session<TGame = unknown> {
  id: string;
  phase: string;
  owner_id: string;
  members: Record<string, SessionMember>;
  game: TGame;
}
