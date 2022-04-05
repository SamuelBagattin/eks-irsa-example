package main

import (
	"encoding/json"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/sts"
	"io/ioutil"
	"log"
	"os"
	"time"
)

func main() {

	// Session creation
	sess := session.Must(session.NewSession())

	// Create a new STS client to get temporary credentials
	initStsClient := sts.New(sess)

	// Getting the SA token
	awsWebIdentityTokenFile := os.Getenv("AWS_WEB_IDENTITY_TOKEN_FILE")

	if awsWebIdentityTokenFile != "" {
		log.Println("Using assumerole with web identity")
		awsRoleArn := os.Getenv("AWS_ROLE_ARN")
		awsWebIdentityToken, err := ioutil.ReadFile(awsWebIdentityTokenFile)
		if err != nil {
			panic(err)
		}

		// Requesting temporary credentials
		identity, err := initStsClient.AssumeRoleWithWebIdentity(
			&sts.AssumeRoleWithWebIdentityInput{
				RoleArn:          aws.String(awsRoleArn),
				RoleSessionName:  aws.String("my-app"),
				WebIdentityToken: aws.String(string(awsWebIdentityToken)),
				DurationSeconds:  aws.Int64(3600),
			})
		if err != nil {
			panic(err)
		}

		// Creating a new session with the temporary credentials
		sess = session.Must(session.NewSession(&aws.Config{
			Credentials: credentials.NewStaticCredentialsFromCreds(credentials.Value{
				AccessKeyID:     *identity.Credentials.AccessKeyId,
				SecretAccessKey: *identity.Credentials.SecretAccessKey,
				SessionToken:    *identity.Credentials.SessionToken,
				ProviderName:    "AssumeRoleWithWebIdentity",
			}),
		}))
	}

	// Create a new sts client from IAM role's credentials and print the current identity
	stsClient := sts.New(sess)
	identity, err := stsClient.GetCallerIdentity(&sts.GetCallerIdentityInput{})
	if err != nil {
		panic(err)
	}
	jsonIdentity, err := json.MarshalIndent(*identity, "", "  ")
	log.Printf("%s", string(jsonIdentity))

	// Create a new S3 client and print all buckets
	s3Client := s3.New(sess)
	buckets, err := s3Client.ListBuckets(&s3.ListBucketsInput{})
	if err != nil {
		panic(err)
	}
	jsonBuckets, err := json.MarshalIndent(*buckets, "", "  ")
	log.Printf("%+v", string(jsonBuckets))
	time.Sleep(time.Hour)
}
