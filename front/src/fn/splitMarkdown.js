// @flow
import slugify from 'slugify';

export type ParsedSection = {
  h2: string,
  id: string,
  text: string,
  path: string
};

export type ParsedSections = ParsedSection[];

export const splitMarkdownSections = (
  text: string,
  urlPrefix: string
): ParsedSections | null => {
  const parts: string[] = text.split('\n## ');
  parts.shift();

  const r = parts.map((part: string) => {
    const heading = part.slice(0, part.indexOf('\n'));
    const sluggedHeading = slugify(heading, { lower: true, strict: true });

    return {
      h2: heading,
      id: sluggedHeading,
      text: `## ${part}`,
      path: `/${urlPrefix}/${sluggedHeading}`
    };
  });

  return r.length ? r : null;
};

export const getMarkdownHeading = (text: string): ?string => {
  const startAt = text.indexOf('# ');

  if (startAt === -1) {
    return null;
  }

  const endAt = text.indexOf('\n', startAt);

  return text.slice(startAt, endAt > 0 ? endAt : undefined);
};

export const updateImagesPaths = (text: string, prefix: string): string => {
  return text.replace(
    /!\[[^\]]*\]\((?<filename>.*?)(?=\"|\))(?<optionalpart>\".*\")?\)/g,
    function(match, filename) {
      const prefixPos = match.lastIndexOf(filename);
      return match.substr(0, prefixPos) + prefix + '/' + match.substr(prefixPos);
    }
  );
}