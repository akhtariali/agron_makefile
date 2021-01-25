# Update these variables to match your repository.

NAME=agron_*
PORT=80*
AWS_ID=203976053147
AWS_REGION=eu-west-1

# DO NOT UPDATE THE FOLLOWING COMMANDS. If you want to change commands, run `make update-tools`

docker-build:
	docker build -t $(NAME) .	
	
docker-run:
	docker run -d -p $(PORT):8080 $(NAME)

docker-test:
	curl -XPOST "http://localhost:$(PORT)/2015-03-31/functions/function/invocations" -d '{"payload":"hello world!"}'

make-docker:
	make docker-build
	make docker-run
	make docker-test

ecr-create:
	aws ecr create-repository --repository-name $(NAME) --image-scanning-configuration scanOnPush=true

docker-tag:
	docker tag $(NAME):latest $(AWS_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(NAME):latest

docker-login: 
	aws ecr get-login-password | docker login --username AWS --password-stdin $(AWS_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

docker-push:
	docker push $(AWS_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(NAME)

lambda-create:
	aws lambda create-function --function-name $(NAME) --code ImageUri=$(AWS_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(NAME):latest --timeout 900 --package-type Image --role arn:aws:iam::$(AWS_ID):role/agron_sp500_adv_dec

lambda-update:
	aws lambda update-function-code --function-name $(NAME) --image-uri $(AWS_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(NAME):latest

lambda-invoke:
	aws lambda invoke --function-name $(NAME) --invocation-type RequestResponse response.json

make-deploy:
ifeq ($(ACTION),create)
		make ecr-create
endif

	make docker-tag
	make docker-login
	make docker-push

ifeq ($(ACTION),create)
		make lambda-create
else
		make lambda-update
endif

	make lambda-invoke

update-tools: ## update-tools: Update this Makefile.
	@curl -sL  https://raw.githubusercontent.com/akhtariali/agron_makefile/master/makefile > n.Makefile
	@read -p "Updated tools from $(VERSION) to $(LATEST).  Do you want to commit and push? [y/N] " Y;\
	if [ "$$Y" == "y" ]; then git add n.Makefile && git commit -m "[min] Updated tools" && git push origin HEAD; fi
	@$(DONE)