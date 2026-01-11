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
        string? SuitableForCsv,
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
        string? SuitableForCsv,
        bool IsVerified,
        DateTime CreatedAtUtc,
        DateTime? UpdatedAtUtc,
        // Geo data
        double? VenueLatitude,
        double? VenueLongitude,
        double? Radius,
        string? VenueAddressLabel,
        double RatingAverage,
        int RatingsCount
    );

    public record VendorRatingRequest(
        [property: Range(1, 5)] int Rating,
        string? Comment
    );

    public record VendorRatingResponse(
        Guid Id,
        Guid VendorUserId,
        Guid MemberUserId,
        int Rating,
        string? Comment,
        DateTime CreatedAtUtc,
        DateTime? UpdatedAtUtc,
        string MemberDisplayName
    );

    public record VendorRatingSummaryResponse(
        double AverageRating,
        int RatingsCount
    );

    public record VendorRatingListResponse(
        VendorRatingSummaryResponse Summary,
        List<VendorRatingResponse> Ratings
    );

    public record VendorQuestionCreateRequest(
        [property: Required, MaxLength(500)] string Question
    );

    public record VendorQuestionAnswerRequest(
        [property: Required, MaxLength(1000)] string Answer
    );

    public record VendorQuestionResponse(
        Guid Id,
        Guid VendorUserId,
        Guid UserId,
        string UserDisplayName,
        string Question,
        string? Answer,
        DateTime CreatedAtUtc,
        DateTime? AnsweredAtUtc
    );
}
