export function isUsernameValid(username: string): boolean {
  if (!username) {
    return false;
  }
  if (username.length < 5 || username.length > 20) {
    return false;
  }
  // Allow letters, numbers, and hyphens
  return /^[a-zA-Z0-9-]+$/.test(username);
}

interface ErrorResponse {
  err: {
    NotFound?: null;
  };
}

export function isError(response: any): response is ErrorResponse {
  return response && response.err !== undefined;
}

export function formatTime(nanoseconds: bigint): string {
  const totalMilliseconds = Number(nanoseconds / 1_000_000n);
  const totalSeconds = Math.floor(totalMilliseconds / 1000);
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;

  return `${hours.toString().padStart(2, "0")}:${minutes.toString().padStart(2, "0")}:${seconds.toString().padStart(2, "0")}`;
}
