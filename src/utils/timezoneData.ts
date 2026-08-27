import { TimeZoneOption } from '../types';

export const POPULAR_TIMEZONES: TimeZoneOption[] = [
  {
    iana: 'America/Los_Angeles',
    city: 'Los Angeles / San Francisco',
    country: 'United States',
    region: 'North America',
    displayName: 'US Pacific (PST/PDT)',
    popular: true,
    commonAbbr: 'PST/PDT',
  },
  {
    iana: 'America/Denver',
    city: 'Denver / Salt Lake City',
    country: 'United States',
    region: 'North America',
    displayName: 'US Mountain (MST/MDT)',
    popular: true,
    commonAbbr: 'MST/MDT',
  },
  {
    iana: 'America/Chicago',
    city: 'Chicago / Dallas / Houston',
    country: 'United States',
    region: 'North America',
    displayName: 'US Central (CST/CDT)',
    popular: true,
    commonAbbr: 'CST/CDT',
  },
  {
    iana: 'America/New_York',
    city: 'New York / Miami / Atlanta',
    country: 'United States',
    region: 'North America',
    displayName: 'US Eastern (EST/EDT)',
    popular: true,
    commonAbbr: 'EST/EDT',
  },
  {
    iana: 'Europe/London',
    city: 'London / Edinburgh / Dublin',
    country: 'United Kingdom',
    region: 'Europe',
    displayName: 'London (GMT/BST)',
    popular: true,
    commonAbbr: 'GMT/BST',
  },
  {
    iana: 'Europe/Paris',
    city: 'Paris / Berlin / Rome / Madrid',
    country: 'France / Germany',
    region: 'Europe',
    displayName: 'Central European (CET/CEST)',
    popular: true,
    commonAbbr: 'CET/CEST',
  },
  {
    iana: 'Europe/Athens',
    city: 'Athens / Bucharest / Helsinki',
    country: 'Greece / Eastern Europe',
    region: 'Europe',
    displayName: 'Eastern European (EET/EEST)',
    popular: true,
    commonAbbr: 'EET/EEST',
  },
  {
    iana: 'Asia/Dubai',
    city: 'Dubai / Abu Dhabi',
    country: 'United Arab Emirates',
    region: 'Middle East',
    displayName: 'Gulf Standard Time (GST)',
    popular: true,
    commonAbbr: 'GST',
  },
  {
    iana: 'Asia/Kolkata',
    city: 'Mumbai / Delhi / Bengaluru',
    country: 'India',
    region: 'Asia',
    displayName: 'India Standard Time (IST)',
    popular: true,
    commonAbbr: 'IST',
  },
  {
    iana: 'Asia/Singapore',
    city: 'Singapore',
    country: 'Singapore',
    region: 'Asia',
    displayName: 'Singapore Time (SGT)',
    popular: true,
    commonAbbr: 'SGT',
  },
  {
    iana: 'Asia/Hong_Kong',
    city: 'Hong Kong',
    country: 'Hong Kong',
    region: 'Asia',
    displayName: 'Hong Kong Time (HKT)',
    popular: true,
    commonAbbr: 'HKT',
  },
  {
    iana: 'Asia/Tokyo',
    city: 'Tokyo / Osaka / Kyoto',
    country: 'Japan',
    region: 'Asia',
    displayName: 'Japan Standard Time (JST)',
    popular: true,
    commonAbbr: 'JST',
  },
  {
    iana: 'Asia/Seoul',
    city: 'Seoul',
    country: 'South Korea',
    region: 'Asia',
    displayName: 'Korea Standard Time (KST)',
    popular: true,
    commonAbbr: 'KST',
  },
  {
    iana: 'Australia/Sydney',
    city: 'Sydney / Melbourne / Canberra',
    country: 'Australia',
    region: 'Oceania',
    displayName: 'Australian Eastern (AEST/AEDT)',
    popular: true,
    commonAbbr: 'AEST/AEDT',
  },
  {
    iana: 'Pacific/Auckland',
    city: 'Auckland / Wellington',
    country: 'New Zealand',
    region: 'Oceania',
    displayName: 'New Zealand (NZST/NZDT)',
    popular: true,
    commonAbbr: 'NZST/NZDT',
  },
  {
    iana: 'America/Sao_Paulo',
    city: 'São Paulo / Rio de Janeiro',
    country: 'Brazil',
    region: 'South America',
    displayName: 'Brasília Time (BRT)',
    popular: true,
    commonAbbr: 'BRT',
  },
  {
    iana: 'America/Toronto',
    city: 'Toronto / Montreal / Ottawa',
    country: 'Canada',
    region: 'North America',
    displayName: 'Canada Eastern Time',
    popular: true,
    commonAbbr: 'EST/EDT',
  },
  {
    iana: 'America/Vancouver',
    city: 'Vancouver',
    country: 'Canada',
    region: 'North America',
    displayName: 'Canada Pacific Time',
    popular: true,
    commonAbbr: 'PST/PDT',
  },
  {
    iana: 'Africa/Cairo',
    city: 'Cairo',
    country: 'Egypt',
    region: 'Africa',
    displayName: 'Egypt Standard Time',
    popular: true,
    commonAbbr: 'EET',
  },
  {
    iana: 'Africa/Johannesburg',
    city: 'Johannesburg / Cape Town',
    country: 'South Africa',
    region: 'Africa',
    displayName: 'South Africa Standard Time',
    popular: true,
    commonAbbr: 'SAST',
  },
  {
    iana: 'UTC',
    city: 'Universal Coordinated Time',
    country: 'International',
    region: 'UTC',
    displayName: 'UTC / GMT',
    popular: true,
    commonAbbr: 'UTC',
  },
];

// Helper to get full comprehensive list of all supported timezones from Intl
export function getAllAvailableTimeZones(): TimeZoneOption[] {
  try {
    if (typeof Intl !== 'undefined' && typeof Intl.supportedValuesOf === 'function') {
      const ianaList = Intl.supportedValuesOf('timeZone');
      const popularIanas = new Set(POPULAR_TIMEZONES.map((tz) => tz.iana));
      
      const additional: TimeZoneOption[] = ianaList
        .filter((tz) => !popularIanas.has(tz))
        .map((tz) => {
          const parts = tz.split('/');
          const region = parts[0] || 'World';
          const rawCity = parts[parts.length - 1]?.replace(/_/g, ' ') || tz;
          return {
            iana: tz,
            city: rawCity,
            country: region,
            region: region,
            displayName: `${rawCity} (${tz})`,
            popular: false,
          };
        });

      return [...POPULAR_TIMEZONES, ...additional];
    }
  } catch {
    // Fallback if Intl.supportedValuesOf is not available
  }
  return POPULAR_TIMEZONES;
}
