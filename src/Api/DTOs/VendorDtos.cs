using System.ComponentModel.DataAnnotations;

namespace MekanBudur.Api.DTOs
{
    public record VendorProfileUpdateRequest(
        [property: Required] string CompanyName,
        string? Description,
        string? VenueType,
        int? Capacity,
        string? Amenities,
        string? PriceRange,
        string? PhoneNumber,
        string? Website,
        string? SocialMediaLinks,
        string? WorkingHours,
        string? PhotoUrls,
        string? ServiceCategoriesCsv,
        // Geo data
        double? VenueLatitude,
        double? VenueLongitude,
        string? VenueAddressLabel
    );

    public record VendorProfileResponse(
        Guid Id,
        Guid UserId,
        string CompanyName,
        string? Description,
        string? VenueType,
        int? Capacity,
        string? Amenities,
        string? PriceRange,
        string? PhoneNumber,
        string? Website,
        string? SocialMediaLinks,
        string? WorkingHours,
        string? PhotoUrls,
        string? ServiceCategoriesCsv,
        bool IsVerified,
        DateTime CreatedAtUtc,
        DateTime? UpdatedAtUtc,
        // Geo data
        double? VenueLatitude,
        double? VenueLongitude,
        double? Radius,
        string? VenueAddressLabel
    );
}
